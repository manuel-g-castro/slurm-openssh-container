# Slurm Docker Cluster with OpenSSH

**Slurm Docker Cluster with OpenSSH** is a single-container Slurm cluster designed for 
CI/CD testing of tools which interface with Slurm. 

## Getting Started

To get up and running with Slurm in Docker, make sure you have the following tools installed:

- **[Docker](https://docs.docker.com/get-docker/)**

Clone the repository:

```bash
git clone https://github.com/manuel-g-castro/slurm-openssh-container.git 
cd slurm-docker-openssh-docker
```

## Architecture 

This setup consists of the executables, launched orderly

- **openssh**: The ssh server.
- **mysql**: Stores job and cluster data.
- **slurmdbd**: Manages the Slurm database.
- **slurmctld**: The Slurm controller responsible for job and resource management.
- **slurmd**: Single compute node.

## Building the Docker Image

Check [Slurm's tags](https://github.com/SchedMD/slurm/tags) and add it as a build
parameter with the `SLURM_TAG` argument.

Generate a public-private pair key to configure the passwordless connection to the 
container.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/container_root_pubkey
cat container_root_pubkey.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8a5WpSERO2+dXt1mISa8oS2Yc7VkSzhy2OuFwqnohP mgimenez@bsces107930
```

Build the image withe `PUBLIC_KEY` argument as the generated public key.

```bash
export SLURM_VERSION=23-02-7-1
docker build . -t autosubmit/slurm-openssh:${SLURM_VERSION}
docker build --build-arg SLURM_TAG='slurm-'${SLURM_VERSION} --build-arg PUBLIC_KEY="$(cat ~/.ssh/container_root_pubkey.pub)" -t autosubmit/slurm-openssh:${SLURM_VERSION} .
```

## Starting the Cluster

Once the image is built, deploy the cluster with the default version of slurm
using Docker run:

```bash
docker run -h slurmctld -p 2222:2222 autosubmit/slurm-openssh:${SLURM_VERSION}
```

The `-h` flag is mandatory so that the slurm deamons accept to start.

Check that it is running and that it is listening to the correct port

```bash
mgimenez@bsces107930 ~ % docker container ls
CONTAINER ID   IMAGE                               COMMAND                  CREATED          STATUS          PORTS                                       NAMES
ece3a5b0b6fe   autosubmit/slurm-openssh:${SLURM_VERSION}    "/tini -- /usr/local…"   21 minutes ago   Up 21 minutes   0.0.0.0:2222->2222/tcp, :::2222->2222/tcp   zen_booth
```

## Accessing the Cluster via SSH

To interact with the Slurm controller, connect to localhost in 2222 with the user 
root.

```bash
mgimenez@bsces107930 ~ % ssh root@localhost -p 2222 -i ~/.ssh/container_root_pubkey sinfo               
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up 5-00:00:00      1   idle slurmctld
```

## Submitting Jobs

Submit jobs through ssh by running the following command:

```bash
mgimenez@bsces107930 ~ % ssh root@localhost -p 2222 -i ~/.ssh/container_root_pubkey sbatch --wrap=\"sleep 20\"
Submitted batch job 1
```

Notice the escaped double quotes around the `--wrap` parameter.

On the window of the container you should see:

```
slurmctld: sched: Allocate JobId=1 NodeList=slurmctld #CPUs=1 Partition=normal
slurmctld: _job_complete: JobId=1 WEXITSTATUS 0
slurmctld: _job_complete: JobId=1 done
```

```
mgimenez@bsces107930 ~ % ssh root@localhost -p 2222 -i ~/.ssh/root_slurm_openssh_container squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 4    normal     wrap     root  R       0:01      1 slurmctld
```

And if you run:

```
mgimenez@bsces107930 ~ % ssh root@localhost -p 2222 -i ~/.ssh/root_slurm_openssh_container sacct -j 1     
JobID           JobName  Partition    Account  AllocCPUS      State ExitCode 
------------ ---------- ---------- ---------- ---------- ---------- -------- 
1                  wrap     normal       root          1  COMPLETED      0:0 
1.batch           batch                  root          1  COMPLETED      0:0
```

## License

This project is licensed under the [MIT License](LICENSE).

