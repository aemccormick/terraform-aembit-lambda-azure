locals {
  lambda_source_hash = base64sha256(join("", [for f in fileset("src", "*") : filebase64sha256("src/${f}")]))
  name               = "aembit-azure-demo"
}

# Create example Lambda function and associated AWS resources
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = local.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_security_group" "lambda" {
  name_prefix = local.name
  description = "Allow all outbound traffic for Lambda function."
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.lambda.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports and protocols
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 14
}

resource "null_resource" "function" {
  depends_on = [null_resource.trust_bundle]
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/function_build.sh"
  }
}

data "archive_file" "lambda_zip" {
  depends_on  = [null_resource.function]
  type        = "zip"
  source_dir  = "${path.module}/build"
  output_path = "${path.module}/artifacts/lambda_function.zip"
}

resource "aws_lambda_function" "example" {
  depends_on       = [null_resource.function]
  architectures    = ["x86_64", ]
  function_name    = local.name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  layers           = [aws_lambda_layer_version.trust_bundle.arn, aws_serverlessapplicationrepository_cloudformation_stack.aembit_proxy_layer.outputs.LayerVersionArn]

  role        = aws_iam_role.iam_for_lambda.arn
  timeout     = 60
  memory_size = 256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      AEMBIT_AGENT_CONTROLLER = var.aembit_agent_controller_url
      AEMBIT_LOG              = var.aembit_agent_log_level
      http_proxy              = "http://localhost:8000"
      https_proxy             = "http://localhost:8000"
      SSL_CERT_FILE           = "/opt/cacert.pem"
      # This variable is only required for Python applications using the requests package
      REQUESTS_CA_BUNDLE = "/opt/cacert.pem"
    }
  }
}

# Create Aembit access policy for Lambda function
module "aembit_lambda_function" {
  depends_on                  = [aembit_server_workload.azure]
  source                      = "git::https://github.com/Aembit/terraform-aembit-access-policies.git?ref=release_1.23.1"
  create_client_workload      = true
  create_trust_providers      = true
  create_credential_providers = true
  client_workload_identifiers = [
    {
      type  = "awsLambdaArn"
      value = aws_lambda_function.example.arn
    },
    # This enables aliased function invocation
    {
      type  = "awsLambdaArn"
      value = "${aws_lambda_function.example.arn}:*"
    }
  ]
  access_policies = {
    azure-graph = {
      is_active                = true
      server_workload_name     = "azure-graph"
      credential_provider_name = "azure-graph"
    }
  }
  trust_providers = {
    aws_role = {
      type = "aws_role"
      aws_role = {
        account_id = var.aws_account_id
        role_arn   = "arn:aws:sts::${var.aws_account_id}:assumed-role/${aws_iam_role.iam_for_lambda.name}/${aws_lambda_function.example.function_name}"
      }
    }
  }
  client_workload_name = local.name
  credential_providers = {
    azure-graph = {
      is_active = true
      type      = "azure_entra_workload_identity"
      azure_entra_workload_identity = {
        audience     = "api://AzureADTokenExchange"
        azure_tenant = var.azure_tenant_id
        client_id    = var.azure_client_id
        scope        = "https://graph.microsoft.com/.default"
        subject      = var.azure_client_subject
      }
    }
  }
}
