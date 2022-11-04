# amazon config
alias init="echo 'running: mwinit && kinit -f' && mwinit && kinit -f"
alias node@12="/opt/homebrew/opt/node@12/bin/node"
alias node@14="/opt/homebrew/opt/node@14/bin/node"
alias habanero-ops="sh /Users/lebedinj/workplace/habops/src/AWSHabaneroOps/habanero-ops"
export JAVA_HOME="/Library/Java/JavaVirtualMachines/amazon-corretto-18.jdk/Contents/Home"
export PATH=$PATH:/Users/lebedinj/.toolbox/bin
export HAB_STAGE=alpha; export HAB_REGION=us-east-1