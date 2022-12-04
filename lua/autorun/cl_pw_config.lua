BLOCK_TAG = {
    "<style>",
    "</style>",
    "<div",
    "</div>",
    "<media",
    "<script",
    "</script>",
    "font-family:",
    "<span",
    "<a",
    "</a>",
    "<body>",
    "</body>",
    "<head>",
    "Bell MT",
}

local list = {1,2,3,4,5,6,7,8,9,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
function gentocken()
    local str = "" 
    while string.len(str) != 4 do
        local int = math.random(1, #list)
        str = str .. list[int]
    end
    return str
end

sizef = GetConVar("pw_sizefont")

if sizef == nil then
    size = "20"
else
    size = sizef:GetInt()
end

STYLE =[[
    <style type="text/css">
    table {
        border-collapse: collapse;
    }
    td {
        border: 1px solid black;
        padding: 4px;
    }
    
    html {
        font-size: ]]..size..[[px;
    }
    </style>
]]