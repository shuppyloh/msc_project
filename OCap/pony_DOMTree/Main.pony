use collections = "collections"
actor Main
    let env: Env
    let main: Main tag
    new create(env':Env)=>
        env = env'
        main = this
        let document: Node = Node.createRoot("Document")
        let access: Bool = initWebPage(document, {(radnode: RNode ref)=>
                try radnode.parent().setProp("title", "Bob website") end 
                }ref)
        env.out.print(access.string())
         
fun ref initWebPage(document: Node, ad_lambda:{(RNode)}):Bool val=>
    try
        document.setProp("title","Alice website")
        let adnode = document.addChild("ad_div")
        let radnode = RNode(adnode, 0)
        ad_lambda(radnode)
        if document.getProp("title") is "Alice website" then return true
            else return false end
    else return false end


class RNode 
    let _node: Node ref 
    let _d: U32
    new ref create(node':Node ref, d':U32)=>
        _node = node'; _d = d'
    fun ref getChild(id:String val):RNode ref?=>
        try RNode.create(_node.getChild(id), _d+1) else error end
    fun ref parent():RNode ref?=>
        if _d > 0 then RNode.create(_node.parent(), _d-1) else error end
    fun box getProp(id:String val):String val ?=>
        try _node.getProp(id) else error end
    fun ref setProp(id:String val,prop:String val)=>
        _node.setProp(id, prop)
    fun ref addChild(id:String val):RNode ref?=>
        try RNode.create(_node.addChild(id), _d+1) else error end
    fun ref delChild(id:String val)?=>
        try _node.delChild(id) else error end
            
class Node
    let name: String
    let _parent: (Node ref|None)
    let _children: collections.Map[String val, Node ref] = _children.create()
    let _props: collections.Map[String val, String val] = _props.create()

    new ref create(name':String, parent': Node ref)=>
        name = name'; _parent = parent'
    new ref createRoot(name':String)=>
        name = name'; _parent = None 
    fun ref getChild(id:String val): Node ref?=>
        try _children(id) else error end
    fun ref parent(): Node ref?=>
        match _parent
        |let x: Node ref => x 
        else error end
    fun box getProp(id:String val):String val ?=>
        try _props(id) else error end
    fun ref setProp(id:String val,prop:String val) =>
        _props(id)=prop
    fun ref addChild(id:String val):Node?=>
        _children(id) = Node.create((name+"-child-"+id.string()), this)
        _children(id)
    fun ref delChild(id:String val) ?=>
        try _children.remove(id) else error end
