# Update README.md with terraform-docs

```powershell
terraform-docs markdown table --output-file README.md --output-mode inject --recursive .
```

# Update terraform.tfvars and terraform.json.tfvars with terraform-docs

```powershell
terraform-docs -c tfvars.hcl.terraform-docs.yml .
terraform-docs -c tfvars.json.terraform-docs.yml .
```

# Generate mkdocs page

```powershell
cd Deploy
docker run --rm -it -p 8000:8000 -v ${PWD}:/docs ds-remote-docker-dev-pb.bas-common.dspace.de/squidfunk/mkdocs-material # hot reload https://squidfunk.github.io/mkdocs-material/creating-your-site/#previewing-as-you-write
docker run --rm -it -v ${PWD}:/docs ds-remote-docker-dev-pb.bas-common.dspace.de/squidfunk/mkdocs-material build # build https://squidfunk.github.io/mkdocs-material/creating-your-site/#building-your-site
```
