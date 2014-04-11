module YTables

using DataFrames, Datetime

export latex_table, org_table

## utility
($)(f::Function, g::Function) = x->f(g(x))


sprintf(fmt, val) = @eval @sprintf($fmt, $val)


## types
abstract YStyle


immutable LatexStyle <: YStyle
    tabular
    align
    format
end


immutable OrgStyle <: YStyle
end


immutable YTable
    data
    style::YStyle
end


## constructors
type_align(_::Number) = "r"
type_align(_::String) = "l"


make_align(data) = [n => type_align(data[1, n]) for n = names(data)]


type_format(_::Integer) = v -> @sprintf("%d", v)
type_format(_::Real)    = v -> @sprintf("%.2f", v)
type_format(_::String)  = v -> @sprintf("%s", v)


make_format(data) = {n => type_format(data[1, n]) for n = names(data)}


formatter(f::String) =   @eval v -> @sprintf($f, v)
formatter(f::Function) = f


formatters(fs) = {k => formatter(v) for (k, v) = fs}


latex_table(data; tabular::String="tabular", alignment=Dict(), format=Dict()) =
    YTable(data, LatexStyle(tabular,
                            merge(make_align(data), alignment),
                            merge(make_format(data), formatters(format))))


org_table(data) = YTable(data, OrgStyle())


## printing
function format_row(row, format::Dict)
    return map(n -> string(format[n](row[n])), names(row))
end


function show_table(io::IO, data::DataFrame, style::LatexStyle)
    println(io, string("% latex table generated in Julia ",
                       VERSION, " by YTables"))
    println(io, string("% ", now()))

    println(io, "\\begin{table}[ht]")
    println(io, "  \\centering")
    println(io, "  \\begin{", style.tabular, "}{",
            join(map(n->style.align[n], names(data)), ""), "}")
    println(io, "    \\hline")
    println(io, "    ", join(map(string, names(data)), " & "), " \\\\")
    println(io, "    \\hline")

    for row = eachrow(data)
        println(io, "    ",
                join(format_row(row, style.format), " & "),
                " \\\\")
    end

    println(io, "    \\hline")
    println(io, "  \\end{tabular}")
    print(io, "\\end{table}")
end


function show_table(io::IO, data::DataFrame, style::OrgStyle)
    ns = names(data)
    println(io, "| ", join(map(string, ns), " | "), " |")
    println(io, "|-", repeat("-+-", length(ns) - 1), "-|")
    for r = eachrow(data)
        println(io, "| ", join(map(n->r[n], ns), " | "), " |")
    end
end


import Base.show
function show(io::IO, t::YTable)
    show_table(io, t.data, t.style)
end

end # module
