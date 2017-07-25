use collections = "collections"
actor Main
    let env: Env
    new create(env':Env)=>
        env = env'
        let alice = Alice.create(env,"alice")
        let bob = Bob.create(env,"bob")
        let question1: U32 = 1097649521
        let question2: U32 = 1000000000
        let question3: U32 = 500000000
        let question4: U32 = 200000000
        alice.ask(bob, question1)
        alice.ask(bob, question2)
        alice.ask(bob, question3)
        alice.ask(bob, question4)

actor Alice  
    let env: Env
    let name: String
    new create(env':Env, name':String)=>
        env = env'; name = name'
    be ask(target: Bob tag, n: U32)=>
        let myself:Alice tag = this
        env.out.print(name+": asking Bob if "+n.string()+" is prime ...")
        target.lambda_call({(target: Bob ref) (myself, n)=> 
            let res: Bool val = target.isPrime(n);
            myself.finished(n,res)
            }val)
    be finished(n: U32 val, result: Bool val)=>
        env.out.print(name+": received results - "+n.string()+" is "+result.string())

//receiver does not have a way to store the capability of its incoming message
//but it allows a caller to execute a lambda, from which the sender can make receiver send a reply
actor Bob
    let env: Env
    let name: String
    let _props: collections.Map[String val, String val] = _props.create()
    new create(env':Env, name':String)=>
        env = env'; name = name'
    //the first val is the capability of the lambda apply method
    //the second val is the capability of the entire function
    be lambda_call(fn:{val (Bob ref)}val) =>
        fn(this)

    fun ref isPrime(n: U32): Bool =>
        var v:U32 = 2
        while v<n do
            if (n%v)==0 then 
            return false end
            v = v + 1
        end 
        true
        
