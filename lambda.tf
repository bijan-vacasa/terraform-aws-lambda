resource "aws_lambda_function" "lambda" {
  count = false == var.attach_vpc_config && false == var.attach_dead_letter_config ? 1 : 0

  # ----------------------------------------------------------------------------
  # IMPORTANT:
  # Changes made to this resource should also be made to "lambda_with_*" below.
  # ----------------------------------------------------------------------------

  function_name                  = var.function_name
  description                    = var.description
  role                           = aws_iam_role.lambda.arn
  handler                        = var.handler
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  runtime                        = var.runtime
  timeout                        = var.timeout
  tags                           = var.tags

  # Use a generated filename to determine when the source code has changed.

  filename = data.external.built.result["filename"]
  depends_on = [
    null_resource.archive,
    aws_cloudwatch_log_group.logs,
  ]

  # The aws_lambda_function resource has a schema for the environment
  # variable, where the only acceptable values are:
  #   a. Undefined
  #   b. An empty list
  #   c. A list containing 1 element: a map with a specific schema
  # Use slice to get option "b" or "c" depending on whether a non-empty
  # value was passed into this module.

  dynamic "environment" {
    for_each = [slice([var.environment], 0, length(var.environment) == 0 ? 0 : 1)]
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      variables = lookup(environment.value, "variables", null)
    }
  }
}

# The vpc_config and dead_letter_config variables are lists of maps which,
# due to a bug or missing feature of Terraform, do not work with computed
# values. So here is a copy and paste of of the above resource for every
# combination of these variables.

resource "aws_lambda_function" "lambda_with_dl" {
  count = var.attach_dead_letter_config && false == var.attach_vpc_config ? 1 : 0

  dead_letter_config {
    target_arn = var.dead_letter_config["target_arn"]
  }

  # ----------------------------------------------------------------------------
  # IMPORTANT:
  # Everything below here should match the "lambda" resource.
  # ----------------------------------------------------------------------------

  function_name                  = var.function_name
  description                    = var.description
  role                           = aws_iam_role.lambda.arn
  handler                        = var.handler
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  runtime                        = var.runtime
  timeout                        = var.timeout
  tags                           = var.tags
  filename                       = data.external.built.result["filename"]
  depends_on = [
    null_resource.archive,
    aws_cloudwatch_log_group.logs,
  ]
  dynamic "environment" {
    for_each = [slice([var.environment], 0, length(var.environment) == 0 ? 0 : 1)]
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      variables = lookup(environment.value, "variables", null)
    }
  }
}

resource "aws_lambda_function" "lambda_with_vpc" {
  count = var.attach_vpc_config && false == var.attach_dead_letter_config ? 1 : 0

  vpc_config {
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    security_group_ids = [var.vpc_config["security_group_ids"]]
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    subnet_ids = [var.vpc_config["subnet_ids"]]
  }

  # ----------------------------------------------------------------------------
  # IMPORTANT:
  # Everything below here should match the "lambda" resource.
  # ----------------------------------------------------------------------------

  function_name                  = var.function_name
  description                    = var.description
  role                           = aws_iam_role.lambda.arn
  handler                        = var.handler
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  runtime                        = var.runtime
  timeout                        = var.timeout
  tags                           = var.tags
  filename                       = data.external.built.result["filename"]
  depends_on = [
    null_resource.archive,
    aws_cloudwatch_log_group.logs,
  ]
  dynamic "environment" {
    for_each = [slice([var.environment], 0, length(var.environment) == 0 ? 0 : 1)]
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      variables = lookup(environment.value, "variables", null)
    }
  }
}

resource "aws_lambda_function" "lambda_with_dl_and_vpc" {
  count = var.attach_dead_letter_config && var.attach_vpc_config ? 1 : 0

  dead_letter_config {
    target_arn = var.dead_letter_config["target_arn"]
  }

  vpc_config {
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    security_group_ids = [var.vpc_config["security_group_ids"]]
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    subnet_ids = [var.vpc_config["subnet_ids"]]
  }

  # ----------------------------------------------------------------------------
  # IMPORTANT:
  # Everything below here should match the "lambda" resource.
  # ----------------------------------------------------------------------------

  function_name                  = var.function_name
  description                    = var.description
  role                           = aws_iam_role.lambda.arn
  handler                        = var.handler
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  runtime                        = var.runtime
  timeout                        = var.timeout
  tags                           = var.tags
  filename                       = data.external.built.result["filename"]
  depends_on = [
    null_resource.archive,
    aws_cloudwatch_log_group.logs,
  ]
  dynamic "environment" {
    for_each = [slice([var.environment], 0, length(var.environment) == 0 ? 0 : 1)]
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      variables = lookup(environment.value, "variables", null)
    }
  }
}

