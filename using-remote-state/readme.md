🌐 Terraform Remote State Collaboration: Networking & Security Module
A hands-on demonstration of Terraform remote state sharing between two independent infrastructure modules — networking and security — using AWS S3 as a backend.

This project shows how teams can collaborate on infrastructure by securely sharing outputs (like an Elastic IP address) across different Terraform configurations, enabling modular, scalable, and team-based DevOps workflows.

🔍 Project Overview
✅ Networking module: Creates an Elastic IP (EIP) in AWS and stores state in an S3 bucket.
✅ Security module: Reads the EIP from remote state and creates a security group rule allowing inbound traffic only from that EIP (/32).
✅ Remote state: Uses AWS S3 
✅ Team collaboration pattern: One team manages networking; another manages security — both use shared data safely.
💡 This mimics real-world scenarios where frontend/backend teams, or DevOps/Security teams work independently but depend on each other’s outputs.

📁 Folder Structure


terraform-remote-state-demo/
├── networking/
│   └── main.tf
├── security/
│   └── main.tf
└── README.md
Each folder is self-contained and can be applied independently after the first one.

⚙️ Prerequisites
Before running this project, ensure you have:



Requirement	Description
AWS Account	With IAM permissions to create: S3 buckets, EIPs, security groups
AWS CLI	Configured with credentials (aws configure)
Terraform v1.5+	Installed locally
S3 Bucket	Named terraform-demo-007-statefile (or update the bucket name in config)
🔒 Best Practice: Use a dedicated S3 bucket with versioning, encryption, and bucket policies. Enable DynamoDB for state locking in production.

🛠️ How It Works
Apply networking first
Terraform initializes the S3 backend.
Creates an Elastic IP (EIP).
Outputs the public IP and saves it to networking.tfstate in S3.
Then apply security
Uses data "terraform_remote_state" to read the eip_address output from the S3-stored state.
Applies a security group rule allowing inbound HTTP (port 80) traffic only from that EIP.
✅ No hardcoded IPs! The dependency is managed via Terraform’s remote state mechanism.

🚀 Step-by-Step Usage
1. Set up S3 Bucket (if not already done)
bash


aws s3 mb s3://terraform-demo-007-statefile --region us-east-1
Enable versioning:

bash


aws s3api put-bucket-versioning --bucket terraform-demo-007-statefile --versioning-configuration Status=Enabled
Optional: Create a DynamoDB table for state locking (recommended for production).

2. Apply Networking Module
bash


cd networking
terraform init
terraform apply
Confirm with yes.
Note the output: eip_address = <your-public-ip>
✅ This writes the state to s3://terraform-demo-007-statefile/networking.tfstate.

3. Apply Security Module
bash


cd ../security
terraform init
terraform apply
Terraform fetches the remote state from S3.
Creates a security group with a rule allowing port 80 from your EIP.
✅ Success! You now have a secure, dynamic rule based on a shared resource.

🧹 Cleanup
Destroy resources when done:

bash


cd security
terraform destroy
cd ../networking
terraform destroy
⚠️ Don’t forget to release the EIP if you don't want ongoing charges.

🎯 Key Learnings


Concept	Why It Matters
terraform_remote_state	Enables cross-module data sharing without hardcoding values.
S3 Backend	Centralized, durable storage for state files.
State Locking (DynamoDB)	Prevents race conditions during concurrent applies.
Modular Infrastructure	Teams can manage their own modules while depending on others.
Dependency Management	Always apply producing modules before consuming ones.
🛡️ Best Practices (Pro Tips)
🔐 Never commit .tfstate files — add them to .gitignore.
🔄 Use workspaces for environments (dev, prod, etc.) with separate state keys.
📦 Use modules to encapsulate logic and reuse across projects.
🧩 Prefer outputs over direct references — keep dependencies clean.
🛠️ Use Terraform Cloud/Enterprise for advanced collaboration, policy enforcement, and audit trails.
