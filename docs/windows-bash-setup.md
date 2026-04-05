# Running Bash Scripts on Windows

Most tools in this repo are written as portable `bash` scripts (`*.sh`). When invoked through a `git` alias — e.g. `git twdiff` — this is transparent: Git for Windows routes `!`-prefixed aliases through its bundled `sh.exe`, so the scripts run identically from Git Bash, CMD, PowerShell, and Windows Terminal with no extra setup.

However, if you want to **invoke `.sh` scripts directly** from CMD or PowerShell (for example to run `install.sh`, or any other bash script in your day-to-day workflow) without opening a separate Git Bash window, the following one-time setup is convenient.

### Add Git's `bash.exe` to your Windows PATH

Git for Windows ships a full bash at:

```
C:\Program Files\Git\bin\bash.exe
```

Add that directory (`C:\Program Files\Git\bin`) to the **system** `PATH` environment variable:

1. Press `Win` and type "Edit the system environment variables" → open it.
2. Click **Environment Variables…**
3. Under **System variables**, select `Path` → **Edit…** → **New**.
4. Paste `C:\Program Files\Git\bin` and click **OK** on all dialogs.
5. Restart any open terminals so they pick up the new `PATH`.

After this, `bash --version` works from CMD, PowerShell, and Windows Terminal.

### PowerShell: alias `bash` so `.sh` scripts can be launched directly

PowerShell cannot execute `.sh` files directly via file association, so `./script.sh` alone will not work. The cleanest workaround is a `bash` alias defined in your PowerShell profile — then `bash script.sh` works from any PowerShell window without spawning a new terminal session.

Open (or create) your PowerShell profile:

```powershell
notepad $PROFILE
```

If the file doesn't exist yet, PowerShell will prompt you to create it. Add this line:

```powershell
# PowerShell can't run bash scripts in the same window, so we alias `bash`
# to Git's bundled bash.exe — lets you run: bash script.sh
Set-Alias -Name bash -Value "C:\Program Files\Git\bin\bash.exe"
```

Save, then reload the profile (or open a new PowerShell window):

```powershell
. $PROFILE
```

Now any `.sh` script in the repo can be run as:

```powershell
bash ./install.sh
bash ./some-other-script.sh
```

The only caveat is that you must prefix the call with `bash` — PowerShell will not auto-resolve `./script.sh` on its own.

### Notes

- Step 1 (adding to `PATH`) is sufficient on its own if you only use CMD or Windows Terminal's `cmd` profile — `script.sh` won't run directly there either, but `bash script.sh` will once `bash.exe` is on `PATH`.
- Step 2 (the PowerShell alias) depends on step 1 being done, or on using the full path in the `Set-Alias` value (as shown above, which does).
- None of this is required for the git aliases in this repo (`git twdiff`, etc.) — those work out of the box from any Windows shell. This setup is purely for the convenience of running `.sh` files directly.
