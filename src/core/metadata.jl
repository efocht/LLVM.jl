import Base: convert

export MDString, MDNode, operands

@reftypedef ref=Value kind=LLVMMetadataAsValueValueKind immutable MetadataAsValue <: Value end

# NOTE: the C API doesn't allow us to differentiate between MD kinds,
#       all are wrapped by the opaque MetadataAsValue...

typealias MDString MetadataAsValue

MDString(val::String) = MDString(API.LLVMMDString(val, Cuint(length(val))))

MDString(val::String, ctx::Context) = 
    MDString(API.LLVMMDStringInContext(ref(Context, ctx), val, Cuint(length(val))))

function convert(::Type{String}, md::MDString)
    len = Ref{Cuint}()
    ptr = API.LLVMGetMDString(ref(Value, md), len)
    ptr == C_NULL && throw(ArgumentError("invalid metadata, not a MDString?"))
    return unsafe_string(convert(Ptr{Int8}, ptr), len[])
end


typealias MDNode MetadataAsValue

function MDNode{T<:Value}(vals::Vector{T})
    _vals = map(v->ref(Value, v), vals)
    return MDNode(API.LLVMMDNode(_vals, Cuint(length(vals))))
end

function MDNode{T<:Value}(vals::Vector{T}, ctx::Context)
    _vals = map(v->ref(Value, v), vals)
    return MDNode(API.LLVMMDNodeInContext(ref(Context, ctx), _vals, Cuint(length(vals))))
end

function operands(md::MDNode)
    nops = API.LLVMGetMDNodeNumOperands(ref(Value, md))
    ops = Vector{API.LLVMValueRef}(nops)
    API.LLVMGetMDNodeOperands(ref(Value, md), ops)
    return map(v->dynamic_construct(Value, v), ops)
end
