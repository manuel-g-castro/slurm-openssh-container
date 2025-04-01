# Slurm Docker Cluster with OpenSSH

**Slurm Docker Cluster with OpenSSH** is a single-container Slurm cluster designed for 
CI/CD testing of tools which interface with Slurm. 

## Getting Started

To get up and running with Slurm in Docker, make sure you have the following tools installed:

- **[Docker](https://docs.docker.com/get-docker/)**

Clone the repository:

```bash
git clone https://github.com/manuel-g-castro/slurm-cluster-openssh-docker.git 
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

Update the `SLURM_TAG` and `IMAGE_TAG` found in the `.env` file and build
the image:

```bash
docker build . -t mmarciani/slurm-cluster-openssh-docker
```

Alternatively, you can build the Slurm Docker image locally by specifying the
[SLURM_TAG](https://github.com/SchedMD/slurm/tags) in the Dockerfile and
tagging the container with a version ***(IMAGE_TAG)***:

```bash
docker build . -t mmarciani/slurm-cluster-openssh-docker:IMAGE_TAG
```

You might want to specify your own public key also in the `Dockerfile` to access the 
container via passwordless connection.

## Starting the Cluster

Once the image is built, deploy the cluster with the default version of slurm
using Docker run:

```bash
docker run -h slurmctld -p 2222:2222 mmarciani/slurm-cluster-openssh-docker
```

The `-h` flag is mandatory so that the slurm deamons accept to start.

Check that it is running and that it is listening to the correct port

```bash
docker container ls
```

## Accessing the Cluster via SSH

To interact with the Slurm controller, connect to localhost in 2222 under
the user root.

```bash
ssh root@localhost -p 2222 -i ~/.ssh/root_slurm_openssh_container sinfo
```

Now you can run any Slurm command from inside the container:

```bash
mgimenez@bsces107930 ~ % ssh root@localhost -p 2222 -i ~/.ssh/root_slurm_openssh_container sinfo               
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up 5-00:00:00      1   idle slurmctld
```

## Submitting Jobs

Submit jobs through ssh by running the following command:

```bash
mgimenez@bsces107930 ~ % ssh root@localhost -p 2222 -i ~/.ssh/root_slurm_openssh_container sbatch --wrap=\"sleep 20\"
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

