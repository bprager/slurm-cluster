-- Create slurm accounting database
CREATE DATABASE IF NOT EXISTS slurm_acct_db;

-- Grant privileges to slurm user
GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'%';
GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';

-- Flush privileges
FLUSH PRIVILEGES;
