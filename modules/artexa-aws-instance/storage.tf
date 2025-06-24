resource "aws_s3_bucket" "bucket" {
  bucket = "${local.instancename}-pkg"
  tags   = var.tags
}

resource "aws_s3_bucket" "bucketlogs" {
  bucket = "${local.instancename}-log"
  tags   = var.tags
}

# [S3.5] S3 buckets should require requests to use Secure Socket Layer
resource "aws_s3_bucket_policy" "ssl_only_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = templatefile("${path.module}/templates/ssl_only_policy.json", { bucket = aws_s3_bucket.bucket.id })
}


#[S3.9] S3 bucket server access logging should be enabled
resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = aws_s3_bucket.bucketlogs.id
  target_prefix = "logs/bucket/${aws_s3_bucket.bucket.id}/"
}

# https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html?icmpid=docs_amazons3_console#how-logs-delivered
resource "aws_s3_bucket_policy" "s3_log_policy" {
  bucket = aws_s3_bucket.bucketlogs.id
  policy = templatefile("${path.module}/templates/s3_log_policy.json", { bucket = aws_s3_bucket.bucketlogs.id })
}


# [S3.14] S3 general purpose buckets should have versioning enabled
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# [S3.4] S3 buckets should have server-side encryption enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}


# [S3.1] S3 general purpose buckets should have block public access settings enabled
resource "aws_s3_bucket_public_access_block" "bucket_access_block" {
  bucket = aws_s3_bucket.bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true # [S3.12] ACLs should not be used to manage user access to S3 general purpose buckets
  restrict_public_buckets = true
}


resource "aws_iam_policy" "s3_policy" {
  name        = "${local.instancename}-s3-policy"
  description = "Allows access to S3 bucket."
  policy      = templatefile("${path.module}/templates/s3_policy.json", { bucket = aws_s3_bucket.bucket.id })
  tags        = var.tags
}


resource "aws_iam_role" "this" {
  count       = var.enable_irsa ? 1 : 0
  name        = "${local.instancename}-models-irsa"
  description = "IAM role for S3 access"
  tags        = var.tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : var.eks_oidc_provider_arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.eks_oidc_issuer}:sub" : "system:serviceaccount:${local.k8s_namespace}:${local.models_serviceaccount}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.enable_irsa ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.s3_policy.arn
}


resource "kubernetes_service_account" "this" {
  count = var.enable_irsa ? 1 : 0
  metadata {
    name      = local.models_serviceaccount
    namespace = kubernetes_namespace.this.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this[0].arn
    }
  }
  automount_service_account_token = false
}


resource "kubernetes_namespace" "this" {
  metadata {

    name = local.k8s_namespace
  }
}

