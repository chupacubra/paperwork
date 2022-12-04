PRINTFORM = {
    NO_FORM = [[
***
> ### HOW TO ADD NEW FORM(for admin server) ###

1.Go to __lua/autorun/listdocs.lua__<br>
2.Add new element in array _PRINTFORM_

EX New_Form = {{}},      {} = []

3.Write in [] your text
***
]],


}

TBLTITLEDOCS = {}
for k,v in pairs(PRINTFORM) do
    table.insert(TBLTITLEDOCS,k)
end
