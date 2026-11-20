# Introduction 
TODO: Give a short introduction of your project. Let this section explain the objectives or the motivation behind this project. 

# Getting Started
TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Run the backend locally
Prerequisites: JDK 21 and Docker Desktop (running). Commands are for Windows PowerShell, from the repo root.

1. Start PostgreSQL 17 and Mailpit: `docker compose up -d`
   - PostgreSQL on `localhost:5432` (`RESOLVEIT_DB_PORT`), database/user/password `resolveit` (dev only)
   - Mailpit SMTP on `localhost:1025` (`RESOLVEIT_MAILPIT_SMTP_PORT`), web UI at http://localhost:8025
     (`RESOLVEIT_MAILPIT_UI_PORT`); see "Port already in use?" below
2. Start the backend with the `dev` profile: `cd backend; .\mvnw.cmd spring-boot:run`
3. Check it:
   - Health: http://localhost:8080/api/v1/health returns `{"status":"UP"}`
   - OpenAPI JSON: http://localhost:8080/api/docs, Swagger UI: http://localhost:8080/api/docs/ui
4. Stop the database: `docker compose down` (add `-v` to delete its data volume)

Configuration comes only from environment variables: `RESOLVEIT_DB_URL`, `RESOLVEIT_DB_USERNAME`,
`RESOLVEIT_DB_PASSWORD`, `SERVER_PORT` (default 8080). The `dev` profile supplies the local defaults above;
without it, the database variables are required.

**Port already in use?** If 5432, 1025 or 8025 is taken on your machine (for example by a Windows
PostgreSQL service or another project's container), `docker compose` cannot publish the port and the backend
may connect to the wrong PostgreSQL. Pick free host ports and set them as user environment variables
(the defaults stay 5432, 1025 and 8025):

```powershell
[Environment]::SetEnvironmentVariable("RESOLVEIT_DB_PORT", "5440", "User")
[Environment]::SetEnvironmentVariable("RESOLVEIT_MAILPIT_SMTP_PORT", "1026", "User")
[Environment]::SetEnvironmentVariable("RESOLVEIT_MAILPIT_UI_PORT", "8026", "User")
```

Open a new terminal (user variables only reach new processes), then `docker compose down; docker compose up -d`.
`docker-compose.yml` publishes these host ports and the `dev` profile builds its default JDBC URL from
`RESOLVEIT_DB_PORT` (an explicit `RESOLVEIT_DB_URL` still wins). To go back to the defaults, remove a variable
with `[Environment]::SetEnvironmentVariable("RESOLVEIT_DB_PORT", $null, "User")`.

Build and test (unit, integration, ArchUnit, Spring Modulith and error-gate tests; needs Docker for
Testcontainers): `cd backend; .\mvnw.cmd clean verify`. Tests always run with the `test` profile, never `dev`.

Error codes: the registry `ErrorCodeRegistry` is published as `contracts/error-codes.json`. After changing
the registry, regenerate the file with `cd backend; .\mvnw.cmd test "-Dtest=ErrorCodeContractTest" "-DupdateContracts=true"`
and commit it.

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)