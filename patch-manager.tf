resource "aws_ssm_maintenance_window" "scan" {
  count             = var.enable_patching ? 1 : 0
  name              = "scan-${var.infrastructurename}"
  cutoff            = 0
  description       = "Maintenance window for scanning for patch compliance"
  duration          = var.maintainance_duration
  schedule          = var.scan_schedule
  schedule_timezone = "UTC"
  tags              = var.tags
}

resource "aws_ssm_maintenance_window" "install" {
  count             = var.enable_patching ? 1 : 0
  name              = "install-${var.infrastructurename}"
  cutoff            = 0
  description       = "Maintenance window for applying patches"
  duration          = var.maintainance_duration
  schedule          = var.install_schedule
  schedule_timezone = "UTC"
  tags              = var.tags
}

resource "aws_ssm_maintenance_window_target" "scan" {
  count         = var.enable_patching ? 1 : 0
  window_id     = aws_ssm_maintenance_window.scan[0].id
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = [local.patchgroupid]
  }
}

resource "aws_ssm_maintenance_window_target" "scan_eks_nodes" {
  count         = var.enable_patching ? 1 : 0
  window_id     = aws_ssm_maintenance_window.scan[0].id
  resource_type = "INSTANCE"

  targets {
    key    = "tag:eks:cluster-name"
    values = [module.eks.eks_cluster_id]
  }

}

resource "aws_ssm_maintenance_window_target" "install" {
  count         = var.enable_patching && var.license_server ? 1 : 0
  window_id     = aws_ssm_maintenance_window.install[0].id
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = [local.patchgroupid]
  }
}

resource "aws_ssm_maintenance_window_task" "scan" {
  count           = var.enable_patching ? 1 : 0
  max_concurrency = 50
  max_errors      = 0
  priority        = 1
  task_type       = "RUN_COMMAND"
  task_arn        = "AWS-RunPatchBaseline"
  window_id       = aws_ssm_maintenance_window.scan[0].id
  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.scan[0].id, aws_ssm_maintenance_window_target.scan_eks_nodes[0].id]
  }
  task_invocation_parameters {
    run_command_parameters {
      comment         = "Runs a compliance scan"
      timeout_seconds = 600

      parameter {
        name   = "Operation"
        values = ["Scan"]
      }
    }
  }
}


resource "aws_ssm_maintenance_window_task" "install" {
  count           = var.enable_patching && var.license_server ? 1 : 0
  max_concurrency = 50
  max_errors      = 0
  priority        = 1
  task_type       = "RUN_COMMAND"
  task_arn        = "AWS-RunPatchBaseline"
  window_id       = aws_ssm_maintenance_window.install[0].id

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.install[0].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment         = "Installs necessary patches"
      timeout_seconds = 600

      parameter {
        name   = "Operation"
        values = ["Install"]
      }
    }
  }
}

resource "aws_ssm_patch_baseline" "production" {
  count            = var.enable_patching && var.license_server ? 1 : 0
  name             = "${var.infrastructurename}-patch-baseline"
  description      = "Default Patch Baseline for Amazon Linux 2 Provided by AWS but with Medium Severity Security Patches."
  operating_system = "AMAZON_LINUX_2"
  approval_rule {
    approve_after_days = 7

    patch_filter {
      key    = "SEVERITY"
      values = ["Important", "Critical", "Medium"]
    }
    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }
  }
  approval_rule {
    approve_after_days = 7

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Bugfix"]
    }
  }
  tags = var.tags
}

resource "aws_ssm_patch_group" "patch_group" {
  count       = var.enable_patching && var.license_server ? 1 : 0
  baseline_id = aws_ssm_patch_baseline.production[0].id
  patch_group = local.patchgroupid
}
