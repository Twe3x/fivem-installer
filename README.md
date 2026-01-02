# FiveM Installer & Updater

A simple Bash script for the fully automated installation and update of a FiveM Server (txAdmin) on Debian-based systems (Ubuntu, Debian, etc.).

## ✨ Features

* **txAdmin Integration**: Sets up txAdmin by default (Port 40120).
* **Artifacts Management**:
    * Automatically detects "Latest" and "Recommended" versions.
    * Supports custom version inputs.
    * Easy **Update** mode for existing installations.
* **Server Data**: Automatically clones `cfx-server-data` and creates a pre-configured `server.cfg`.
* **Database (Optional)**:
    * Installation of MariaDB & PHPMyAdmin (via integrated installer).
    * Automatic creation of a `fivem` database and user.
* **Management**:
    * Generates helper scripts: `start.sh`, `stop.sh`, `attach.sh`.
    * Runs inside a `screen` session for stability.
* **Auto-Start**: Optional Crontab setup (`@reboot`) to automatically start the server after a system reboot.

## 📋 Prerequisites

* **OS**: Debian, Ubuntu, or other Debian-based distributions.
* **Permissions**: Root access is required.
* **Ports**: By default, ports `30120` (Game) and `40120` (txAdmin) are required.

## 🚀 Installation (Quick Start)

Simply run the following command as **root** to start the interactive menu:

```bash
bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/setup.sh)
```

Follow the on-screen instructions. You can choose between:
1.  **Install FiveM**: Fresh installation.
2.  **Update FiveM**: Update artifacts of an existing installation.

## 🛠️ Server Management

After installation, the server is located in `/home/FiveM` by default. You will find the following helper scripts there:

| Command | Description |
| :--- | :--- |
| `sh /home/FiveM/start.sh` | Starts the server (if not already running). |
| `sh /home/FiveM/stop.sh` | Stops the server (terminates the screen session). |
| `sh /home/FiveM/attach.sh` | Opens the live console (Screen Session). Detach with `CTRL+A` then `D`. |

**txAdmin Login:**
At the end of the installation, the script will display the URL (e.g., `http://your-ip:40120`) and the **PIN Code** required for the initial setup.

## 🤖 CLI Options (Advanced / Automation)

The script can be controlled entirely without user interaction, making it ideal for automated installation.

**General Options:**

| Option | Description |
| :--- | :--- |
| `--non-interactive` | Skips all prompts (requires additional flags). |
| `-v, --version <URL\|latest>` | Selects a specific version or "latest". |
| `-u, --update <path>` | Starts update mode for the specified directory. |
| `-c, --crontab` | Enables automatic start on system reboot. |
| `--no-txadmin` | Disables txAdmin and uses pure `cfx-server-data`. |
| `--kill-port` | Forcefully kills processes on port 40120 if in use. |
| `--delete-dir` | Deletes the installation directory (`/home/FiveM`) if it exists (Use with caution!). |

**Database & PHPMyAdmin Options:**

| Option | Description |
| :--- | :--- |
| `-p, --phpmyadmin` | Enables installation of MariaDB and PHPMyAdmin. |
| `--security` | (Required for non-interactive) Selects secure installation mode for PMA. |
| `--simple` | (Required for non-interactive) Selects simple installation mode. |
| `--db_user <name>` | Sets the database username. |
| `--db_password <pw>` | Sets the database password. |
| `--generate_password` | Automatically generates a secure database password. |

**Example for a fully automated installation:**
```bash
bash <(curl -s https://raw.githubusercontent.com/Twe3x/fivem-installer/main/setup.sh) --non-interactive --crontab --version latest --phpmyadmin --simple --generate_password
```

## 📂 File Structure

The default installation directory is `/home/FiveM`.

```text
/home/FiveM/
├── server/          # FiveM Artifacts (FXServer)
├── server-data/     # Resources and server.cfg
├── start.sh         # Start script
├── stop.sh          # Stop script
└── attach.sh        # Open console
```

## 🤝 Contributing

Pull requests are welcome!

## 📜 License

This project is distributed under the **GPL-3.0** License. See [LICENSE](LICENSE) for details.

Credits:
* Uses [PHPMyAdminInstaller](https://github.com/JulianGransee/PHPMyAdminInstaller) by JulianGransee.
* Uses [BashSelect](https://github.com/JulianGransee/BashSelect.sh) for menus by JulianGransee.