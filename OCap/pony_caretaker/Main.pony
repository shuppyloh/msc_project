//The purpose of this snippet is to demonstrate below the use an attenuating object,
//caretaker, to mediate access in an OCap system. 
use collections = "collections"
actor Main
    let env: Env
    new create(env':Env)=>
        env = env'
        env.out.print("---Initial Conditions---")
        let alice: SimpleObj ref = SimpleObj.create(env,"alice")
        let bob: SimpleObj ref = SimpleObj.create(env,"bob")
        let carol: SimpleObj ref = SimpleObj.create(env,"carol")
        let diane: SimpleObj ref = SimpleObj.create(env,"diane")
        try
        //initial conditions
        alice.recCap("bob",bob)
        alice.recCap("carol",carol)
        carol.recCap("diane",diane)
        diane.sendProp("diane_prop1","true","diane")
        env.out.print("---Initial Conditions Completed---")

        //Alice passing a caretaker for Carol, to Bob for Bob's use
        alice.createCareT("carol-CT","carol") //carol-CT caretaker created
        alice.sendCap("carol-CT","bob") //alice sends carol-CT to bob
        //Bob sending his own capability to Carol
        bob.sendCap("bob","carol-CT")
        //Carol sending Diane's capability to Bob
        carol.sendCap("diane","bob")
        //Bob tells sets prop1 in Carol to be true
        bob.sendProp("carol_prop1","true","carol-CT") //bob sends property (prop1 = true) to carol-CT
        env.out.print("MAIN:carol_prop1 is "+carol.getProp("carol_prop1")) //this carol's prop1 should return true

        //POST-LOCK

        //Alice changes lock of Carol-CT
        alice.changelock(true,"carol-CT-lock") //alice locks carol-CT
        //Bob tries to change prop1=false on carol-CT and the lock should prevent him from doing so
        bob.sendProp("carol_prop1","false","carol-CT") //bob tries to change prop1 = false to carol-CT
        env.out.print("MAIN:carol_prop1 is "+carol.getProp("carol_prop1")) //this carol's prop1 should return true
        //Bob tries to change prop1=false on diane and will succeed because nothing is preventing him from doing so
        bob.sendProp("diane_prop1","false","diane") //bob tries to change prop1 = false to diane
        env.out.print("MAIN:diane_prop1 is "+diane.getProp("diane_prop1")) //because caretaker is locked, should return true

        end
        
class Lock
    var _state: Bool val 
    new ref create()=>
        _state = false
    fun ref unlock()=>
        _state = false 
    fun ref lock()=>
        _state = true 
    fun box state():Bool val=>
        _state

class Caretaker 
    let _target: (Caretaker ref|SimpleObj ref)
    var _lock: Lock ref  
    new ref create(target':(Caretaker ref|SimpleObj ref), lock':Lock ref)=>
        _target = target'
        _lock = lock'
    fun box _locked():Bool val=>
        _lock.state()
    fun box getProp(id:String val):String val?=>
        try
            if _locked() is false then _target.getProp(id) else error end
        else error end
    fun ref sendProp(id:String val,prop:String val,rec: String val)?=>
        try
            if _locked() is false then _target.sendProp(id,prop,rec) else error end
        else error end
    fun ref recProp(id:String val,prop:String val)=>
        if _locked() is false then _target.recProp(id,prop) end
    fun ref getCap(id:String val): (SimpleObj ref|Lock ref|Caretaker ref)?=>
        try
            if _locked() is false then _target.getCap(id) else error end
        else error end
    fun ref sendCap(id:String val, rec:String val)?=>
        try
            if _locked() is false then _target.sendCap(id,rec) end
        else error end
    fun ref recCap(id:String val, cap':(SimpleObj ref|Lock ref|Caretaker ref))=>
        if _locked() is false then _target.recCap(id,cap') end
    fun ref delCap(id:String val)?=>
        try
            if _locked() is false then _target.delCap(id) end
        else error end
    fun ref createCareT(id:String val,target:String val):Caretaker ref?=>
        try
            if _locked() is false then _target.createCareT(id,target) else error end
        else error end
            
class SimpleObj
    let env: Env
    let name: String
    let _caps: collections.Map[String val, (SimpleObj ref|Lock ref|Caretaker ref)] = _caps.create()
    let _props: collections.Map[String val, String val] = _props.create()

    new ref create(env':Env, name':String)=>
        env = env'; name = name'
        _caps(name)=this
    fun ref changelock(lock:Bool val,rec: String val)?=>
        try if lock is true then (getCap(rec) as Lock ref).lock() 
        else (getCap(rec) as Lock ref).unlock() end
        env.out.print(name+": changing lock of "+rec+" to "+lock.string())
        else error end
    fun box getProp(id:String val):String val ?=>
        try _props(id) else error end
    fun ref sendProp(id:String val,prop:String val,rec: String val)?=>
        env.out.print(name+":sending ("+id+" as "+prop+") to "+rec)
        try (getCap(rec) as (Caretaker ref|SimpleObj ref)).recProp(id,prop) else error end
    fun ref recProp(id:String val,prop:String val) =>
        env.out.print(name+":"+id+" changed to "+prop)
        _props(id)=prop
    fun ref getCap(id:String val): (SimpleObj ref|Lock ref|Caretaker ref)?=>
        try  _caps(id) else error end
    fun ref sendCap(id:String val, rec:String val)?=>
        env.out.print(name+":sending capability of "+id+" to "+rec)
        try (getCap(rec) as (Caretaker ref|SimpleObj ref)).recCap(id, getCap(id)) else error end
    fun ref recCap(id:String val, cap':(SimpleObj ref|Lock ref|Caretaker ref))=>
        _caps(id) = cap'
        env.out.print(name+":received capability of "+id)
    fun ref delCap(id:String val) ?=>
        try _caps.remove(id) else error end
    fun ref createCareT(id:String val,target':String val):Caretaker ref?=>
        env.out.print(name+":creating caretaker "+id+" for "+target')
        try
            let cap = (getCap(target') as (Caretaker ref|SimpleObj ref))
            let lockname: String val = id+"-lock"
            let lock:Lock ref = Lock.create() 
            let caretaker:Caretaker ref = Caretaker.create(cap,lock) 
            recCap(lockname, lock) 
            recCap(id, caretaker)
            caretaker
        else error end
