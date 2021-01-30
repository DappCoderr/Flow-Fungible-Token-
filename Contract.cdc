import FungibleToken from 0x9a0766d93b6608b7

pub contract CLToken: FungibleToken{


    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address? )
    pub event TokensBurned(amount: UFix64)
    pub event MinterCreated(amount: UFix64)
    pub event TokenMinted(amount: UFix64)
    pub event TokenInitialized(initialSupply: UFix64)

    pub let VaultStoragePath: Path
    pub let ReceiverPublicPath: Path    
    pub let BalancePublicPath: Path
    pub let AdminStoragePath: Path

    pub var totalSupply: UFix64

    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{
        pub var balance: UFix64
        init(balance: UFix64){
            self.balance = balance
        }

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault{
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        pub fun deposite(from: @FungibleToken.Vault){
            let vault <- from as! @CLToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: amount, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy(){
            CLToken.totalSupply = CLToken.totalSupply - self.balance
            emit TokensBurned(amount: self.balance)
        }
    }

    pub fun createEmptyVaullt(): @Vault{
        return <- create Vault(balance: 0.0)
    }

    pub resource Administrator{

        pub fun createNewMinter(allowedAmount: UFix64): @Minter{
            emit MinterCreated(allowedAmount: allowedAmount)
            return <- create Minter(allowedAmount: allowedAmount)
        }
    }

    pub resource Minter{
        pub var allowedAmount: UFix64
        
        pub fun mintTokens(amount: UFix64): @CLToken.Vault{
            pre{
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than allowed amount"
            }
            CLToken.totalSupply = CLToken.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokenMinted(amount: amount)
            return <- create Vault(balance: amount)
        }

        init(allowedAmount: UFix64){
            self.allowedAmount = allowedAmount
        }
    }

    init(){
        self.VaultStoragePath = /storage/CLTokenVault
        self.ReceiverPublicPath = /public/CLTokenReceiver
        self.BalancePublicPath = /public/CLTokenBalance
        self.AdminStoragePath = /storage/CLTokenAdmin

        self.totalSupply = 0.0
        let admin <- create Administrator()
        self.account.save(<-admin, to: self.AdminStoragePath)
        emit TokenInitialized(initialSupply: self.totalSupply)
    }

}














