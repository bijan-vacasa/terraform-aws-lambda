# Create the role.

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = var.function_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach a policy for logs.

data "aws_iam_policy_document" "logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*",
    ]
  }
}

resource "aws_iam_policy" "logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name   = "${var.function_name}-logs"
  policy = data.aws_iam_policy_document.logs[0].json
}

resource "aws_iam_policy_attachment" "logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name       = "${var.function_name}-logs"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.logs[0].arn
}

resource "aws_cloudwatch_log_group" "logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name = "/aws/lambda/${var.function_name}"
  tags = var.tags
}

# Attach an additional policy required for the dead letter config.

data "aws_iam_policy_document" "dead_letter" {
  count = var.attach_dead_letter_config ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
      "sqs:SendMessage",
    ]

    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    resources = [
      lookup(var.dead_letter_config, "target_arn", ""),
    ]
  }
}

resource "aws_iam_policy" "dead_letter" {
  count = var.attach_dead_letter_config ? 1 : 0

  name   = "${var.function_name}-dl"
  policy = data.aws_iam_policy_document.dead_letter[0].json
}

resource "aws_iam_policy_attachment" "dead_letter" {
  count = var.attach_dead_letter_config ? 1 : 0

  name       = "${var.function_name}-dl"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.dead_letter[0].arn
}

# Attach an additional policy required for the VPC config

data "aws_iam_policy_document" "network" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "network" {
  count = var.attach_vpc_config ? 1 : 0

  name   = "${var.function_name}-network"
  policy = data.aws_iam_policy_document.network.json
}

resource "aws_iam_policy_attachment" "network" {
  count = var.attach_vpc_config ? 1 : 0

  name       = "${var.function_name}-network"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.network[0].arn
}

# Attach an additional policy if provided.

resource "aws_iam_policy" "additional" {
  count = var.attach_policy ? 1 : 0

  name   = var.function_name
  policy = var.policy
}

resource "aws_iam_policy_attachment" "additional" {
  count = var.attach_policy ? 1 : 0

  name       = var.function_name
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.additional[0].arn
}

