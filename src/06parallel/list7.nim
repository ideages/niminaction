import re  

let pattern = re"([^\s]+)\s([^\s]+)\s(\d+)\s(\d+)"    

var line = "en Nim_(programming_language) 1 70231"
var matches: array[4, string]   
let start = find(line, pattern, matches)   
doAssert start == 0             
doAssert matches[0] == "en"                           
doAssert matches[1] == "Nim_(programming_language)"   
doAssert matches[2] == "1"                            
doAssert matches[3] == "70231"                        
echo("Parsed successsfully!")

