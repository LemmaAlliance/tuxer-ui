# Contributing to Tuxer-UI

Thank you for considering contributing to Tuxer-UI! Your help is valuable to us. Please follow the guidelines below to make the contribution process easy and effective for everyone involved.

## Code of Conduct

By participating in this project, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

1. **Fork the repository**: Start by forking the repository to your GitHub account.

2. **Clone your fork**: Clone the forked repository to your local machine.

    ```bash
    git clone https://github.com/YOUR-USERNAME/tuxer-ui.git
    cd tuxer-ui
    ```

3. **Set up your development environment**: Follow the instructions below to set up your development environment.

### Development Environment Setup

For Debian-based systems:

```bash
sudo apt update
sudo apt install gcc binutils nasm
```
Makefile Commands:
The repository uses a Makefile for managing builds. Below are the key commands:

Install dependencies:

```bash
make deps
```
Compile the code:

```bash
make
```
Run the binary:

```bash
make run
```
Clean the build directory:

```bash
make clean
```
Please note that you should never push with an empty build directory.

Making Changes
Create a branch: Create a new branch from the main branch for your changes.

```bash
git checkout -b feature/my-new-feature
```
Make your changes: Make the necessary changes to the codebase.

Commit your changes: Commit your changes with a clear and descriptive commit message.

```bash
git add .
git commit -m "Add feature: description of the feature"
```
Push to your fork: Push your changes to your fork on GitHub.

```bash
git push origin feature/my-new-feature
```
Create a pull request: Go to the original repository on GitHub and create a pull request from your forked repository.

License
By contributing to Tuxer-UI, you agree that your contributions will be licensed under the GNU Affero General Public License v3.0.

Getting Help
If you need any help, please feel free to reach out by opening an issue. We appreciate your contributions and look forward to collaborating with you!

Thank you for contributing!
