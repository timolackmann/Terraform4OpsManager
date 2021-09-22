#region of your deployment of Ops Manager and Agents
region       = "eu-central-1"
#AWS instance typ of Ope Manager deploymen (recommended: t2.xlarge)
instancetype = "t2.xlarge"

#tags for AWS instances to protect from the reaper process
expire_on    = "2021-09-18"
purpose      = "training"
keyName      = "timolackmann"
ownerName    = "timo.lackmann"
initials     = "tl"

#absolut path to your SSH key (e.g. /Users/timo.lackmann/Downloads/timolackmann.pem)
keyPath      = "/Users/timo.lackmann/Downloads/timolackmann.pem"

#details of the inital Ops Manager User
opsManagerUser = "Timo.Lackmann@mongodb.com"
opsManagerPass = "Passw0rd."
opsManagerFirstname = "Timo"
opsManagerLastname = "Lackmann"

#Configuration of nodes that will be added to the Ops Manager for MongoDB Deployments
agentNodecount = 3
agentInstancetype = "t2.large"