# COSC2759 Assignment 2 - Semester 2, 2025

# Services


## Backend
This is the Backend Posts Service. It is responsible for talking to the Posts DB, and exposing an internal HTTP API for managing Posts.

### Environment Variables
| Environment Variable | Purpose                                                 |
|----------------------|---------------------------------------------------------|
| PORT                 | Which port will the service listen on for HTTP requests |
| DB_USER              | Username for connecting to the Backend DB               |
| DB_PASSWORD          | Password for connecting to the Backend DB               |
| DB_HOST              | Hostname/Network address for the Backend DB             |

### Image
The Backend service image is available at `rmitdominichynes/sdo-2025:backend`.

### Dependencies
The Backend service depends on a PostgreSQL database, with the required migrations. An image for this has been provided, available at `rmitdominichynes/sdo-2025:db`.

### Database Configuration
The PostgreSQL Databse container also requires some environment variables to be configured.

|  Environment Variable        |  Purpose                                                  |
|------------------------------|-----------------------------------------------------------|
|  POSTGRES_USER               | Username for the Backend Service to use to connect        |
|  POSTGRES_PASSWORD           | Password for the Backend Service to use to connect        |
|  POSTGRES_DB                 | "posts"                                                   |

## Frontend
This is the Frontend Posts Service. It is responsible for serving a UI to users over HTTP. This UI allows them to view and manage Posts.

### Environment Variables
| Environment Variable | Purpose                                                 |
|----------------------|---------------------------------------------------------|
| PORT                 | Which port will the service listen on for HTTP requests |
| BACKEND_URL          | Fully qualified URL for reaching the Backend Service    |

### Image
The Frontend service image is available at `rmitdominichynes/sdo-2025:frontend`.


# Running The Services Locally (In Docker)
1. Run `docker compose up -d` to start the two services, and a postgres database container.
2. View the Frontend Posts Service at `http://localhost:8081`, and the Backend Posts Service at `http://localhost:8080`.

# Deploying The Services

The services can be deployed to EC2. 

Each container needs: 
- The correct environment variables configured (refer to the above sections)
- Security Groups will need to be configured to allow traffic to reach the instances. 
    - They will also need to be configured to allow the instances to talk to each other, if the services are deployed on different instances.
    - The PostgreSQL database receives inbound traffic on port `5432`
    - The ports used by the Backend and Frontend services are configurable through the `PORT` environment variable. Otherwise, it will default to port `8081`.


### Section A: Task 2: Automated Deployment

Run a full deployment with one command.

**requirement**
- AWS CLI logged in to the correct account
- Terraform and Ansible installed
- EC2 key pair named `assignment2key` in **us-east-1** (private key at `~/.ssh/assignment2key`)

**Deploy**
```bash
ansible-galaxy collection install community.docker
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Section A: Task 3a: Backend connects to Database

This step ensures the Backend container can connect to the Database container on the same EC2 instance.

**How to verify**
- Run the deployment: `./scripts/deploy.sh`
- In the Ansible output, look for:  
  `TASK [backend : Assert backend connected to DB]` -> **ok**

**What this does**
- Starts PostgreSQL (`posts_db`) and waits for it to be ready.
- Starts the Backend (`posts_backend`) with DB env vars.
- Reads backend logs and **fails** if typical DB-connection errors are found.


### Section A: Task 3b: Backend is publicly reachable

The backend API is exposed/reachable to the internet.

**How to verify**
- After deploy: `./scripts/deploy.sh`
- Get the EC2 IP printed by the script, then open:
  - `http://<ip>:8080/` in a browser, or
  - `curl -i http://<ip>:8080/`
- Expected: a JSON response `{"status":"OK","service":"backend","db":"OK"}`.


### Section B: Task 4: Frontend is publicly reachable

A frontend container is deployed on the same EC2 host and reachable on **port 80**.

**How to verify**
- Run: `./scripts/deploy.sh`
- Open: `http://<EC2_PUBLIC_IP>/`
- Expected: Frontend page loads and shows green checks for “Backend Status” and “Backend -> DB Status”.



### Section B: Task 5: Frontend can reach the Backend

Frontend runs with `BACKEND_URL` set to the EC2 public IP and backend `port 8080`, and is published as `host 80 -> container 8081`.

**How to verify**
- Run: ./scripts/deploy.sh
- Open: http://<EC2_PUBLIC_IP>/
- Expected: Backend Status ✅ and Backend -> DB Status ✅ are both green.


### Section C: Task 6: Split EC2 (frontend/public, backend/public, DB/private)

This script makes the infrastructure and configures the apps end-to-end.
using Terraform and Ansible.
Security groups expose only what’s needed (80 for frontend, 8080 for backend) and the DB stays private.

Runs three EC2 instances: 
- **Frontend** (public) on port **80** 
- **Backend** (public) on port **8080** 
- **Database** (private subnet IP only) **How to run**

```bash
./scripts/deploy.sh
```