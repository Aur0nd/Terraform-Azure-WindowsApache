# Terraform-Azure-WindowsApache
Deploy highly available Apache on Azure with Terraform (Windows)


|-------------------------------------------------------------|
This deployment was created for learning purposes and Reference
|-------------------------------------------------------------|

1) Create a Resource group manually and name it state
  - Create a new blobe (Storage account) and name it tfstateaur
  - Create a Key Vault and name it tfman

|-------------------------------------------------------------|
NOTE: Of course, you can name the resources however you want, just make sure you name the Variables accordingly
|-------------------------------------------------------------|

2) cd Terraform-Azure
  - terraform init
    - terraform apply
    
3) cd Terraform-Azure/bastion
   - terraform init
     - terraform apply
