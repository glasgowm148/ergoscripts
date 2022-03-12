
> Note : Work-in-progress.



# Getting Started

Tested primarily on OSX/Pi

```
bash -c "$(curl -s https://node.phenotype.dev)"
```

## Raspberry Pi

This assumes a clean device.

### Installation prep
```
sudo apt update && sudo apt upgrade -y
```

### Download necessary packages
```
sudo apt install default-jdk git lsof -y
```

### Clone the repo
```
git clone https://github.com/glasgowm148/ergoscripts
```

### Execute script
```
cd ergoscripts
bash -c "$(curl -s https://node.phenotype.dev)"
```

You'll need to 1) enter a password and 2) determine if you want this to launch on mainnet or testnet.

### Validate
```
curl http://127.0.0.1:9053/info
```

If everything is working as intended then the `headersHeight` value should increase in value over time.

# Features

- Downloads latest .jar file
- Prompts and sets API key
- Track progress by percentage in CLI
- Set config specific to platform (Unix/Win/Pi)
- Logs & attempts to solve common problems.

![CLI](/run.png)

# References

- [1](https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux)
- [Grep -P no longer works](https://stackoverflow.com/questions/16658333/grep-p-no-longer-works-how-can-i-rewrite-my-searches)
