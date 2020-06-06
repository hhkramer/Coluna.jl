abstract type AbstractVarConstr end
abstract type AbstractVarConstrId end
abstract type AbstractState end
abstract type AstractMoiDef end
abstract type AbstractMembership end
abstract type AbstractVcData end
abstract type AbstractOptimizer end

# Interface (src/interface.jl)
struct Primal <: Coluna.AbstractPrimalSpace end
struct Dual <: Coluna.AbstractDualSpace end

struct MinSense <: Coluna.AbstractMinSense end
struct MaxSense <: Coluna.AbstractMaxSense end

#
# Duties for variables and constraints
#
"""
    Duty{Variable}

Duties of a variable are tree-structured values wrapped in `Duty{Variable}` instances. 
Leaves are concret duties of a variable, intermediate nodes are duties representing 
families of duties, and the root node is a `Duty{Variable}` with value `1`.

    Duty{Constraint}

It works like `Duty{Variable}`.

# Examples

If a duty `Duty1` inherits from `Duty2`, then 

```jldoctest
julia> Duty1 <= Duty2
true
````
"""
struct Duty{VC <: AbstractVarConstr} <: NestedEnum
    value::UInt
end

# Source : https://discourse.julialang.org/t/export-enum/5396
macro exported_enum(name, args...)
    esc(quote
        @enum($name, $(args...))
        export $name
        $([:(export $arg) for arg in args]...)
        end)
end

@exported_enum VarSense Positive Negative Free
@exported_enum VarKind Continuous Binary Integ
@exported_enum ConstrKind Essential Facultative SubSystem
@exported_enum ConstrSense Greater Less Equal

# TODO remove following exported_enum
@exported_enum FormulationPhase HybridPhase PurePhase1 PurePhase2 # TODO : remove from Benders
#@exported_enum VcSelectionCriteria Static Dynamic Delayed Artificial Implicit Explicit # Not used
#@exported_enum SolutionMethod DirectMip DantzigWolfeDecomposition BendersDecomposition # Not used

const FormId = Int

############################################################################
######################## MathOptInterface shortcuts ########################
############################################################################
# Objective function
const MoiObjective = MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}

# Constraint
const MoiConstrIndex = MOI.ConstraintIndex
MoiConstrIndex{F,S}() where {F,S} = MOI.ConstraintIndex{F,S}(-1)
MoiConstrIndex() = MOI.ConstraintIndex{
    MOI.ScalarAffineFunction{Float64},MOI.LessThan{Float64}
}()

# Variable
const MoiVarIndex = MOI.VariableIndex
MoiVarIndex() = MOI.VariableIndex(-1)

# Bounds on variables
const MoiVarBound = MOI.ConstraintIndex{MOI.SingleVariable,MOI.Interval{Float64}}

# Variable kinds
const MoiInteger = MOI.ConstraintIndex{MOI.SingleVariable,MOI.Integer}
const MoiBinary = MOI.ConstraintIndex{MOI.SingleVariable,MOI.ZeroOne}
const MoiVarKind = Union{MoiInteger,MoiBinary}
MoiVarKind() = MoiInteger(-1)

# Helper functions to transform MOI types in Coluna types
convert_moi_sense_to_coluna(::MOI.LessThan{T}) where {T} = Less
convert_moi_sense_to_coluna(::MOI.GreaterThan{T}) where {T} = Greater
convert_moi_sense_to_coluna(::MOI.EqualTo{T}) where {T} = Equal
convert_moi_rhs_to_coluna(set::MOI.LessThan{T}) where {T} = set.upper
convert_moi_rhs_to_coluna(set::MOI.GreaterThan{T}) where {T} = set.lower
convert_moi_rhs_to_coluna(set::MOI.EqualTo{T}) where {T} = set.value
convert_moi_kind_to_coluna(::MOI.ZeroOne) = Binary
convert_moi_kind_to_coluna(::MOI.Integer) = Integ

function convert_coluna_sense_to_moi(constr_set::ConstrSense)
    constr_set == Less && return MOI.LessThan
    constr_set == Greater && return MOI.GreaterThan
    return MOI.EqualTo
end
############################################################################

"""
    AbstractFormulation

    Formulation is a mathematical representation of a problem 
    (model of a problem). A problem may have different formulations. 
    We may rename "formulation" to "model" after.
    Different algorithms may be applied to a formulation.
    A formulation should contain a dictionary of storages
    used by algorithms. A formulation contains one storage 
    per storage type used by algorithms.    
"""
abstract type AbstractFormulation <: AbstractModel end

