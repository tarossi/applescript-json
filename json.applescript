on decodeWithDicts(value)
	set s to "import json, sys, codecs" & return
	set s to s & "sys.stdin = codecs.getreader('utf8')(sys.stdin)" & return
	set s to s & "def toAppleScript(pythonValue):" & return
	set s to s & "    output = ''" & return
	set s to s & "    if(pythonValue == None):" & return
	set s to s & "        output += 'null'" & return
	set s to s & "    elif (isinstance(pythonValue, dict)):" & return
	set s to s & "        output += 'json\\'s createDictWith({'" & return
	set s to s & "        first = True" & return
	set s to s & "        for (key, value) in pythonValue.iteritems():" & return
	set s to s & "            if first:" & return
	set s to s & "                first = False" & return
	set s to s & "            else:" & return
	set s to s & "                output += ','" & return
	set s to s & "            output += '{' + json.dumps(key) + ',' " & return
	set s to s & "            output += toAppleScript(value) + '}' " & return
	set s to s & "        output += '})'" & return
	set s to s & "    elif (isinstance(pythonValue, list)):" & return
	set s to s & "        output += '{'" & return
	set s to s & "        first = True" & return
	set s to s & "        for value in pythonValue:" & return
	set s to s & "            if first:" & return
	set s to s & "                first = False" & return
	set s to s & "            else:" & return
	set s to s & "                output += ','" & return
	set s to s & "            output += toAppleScript(value)" & return
	set s to s & "        output += '}'" & return
	set s to s & "    elif(isinstance(pythonValue, basestring)):" & return
	set s to s & "        output += '\"' + pythonValue.replace('\"', '\\\\\"') + '\"'" & return
	set s to s & "    else:" & return
	set s to s & "        output += json.dumps(pythonValue)" & return
	set s to s & "    return output" & return
	-- sys.stdout to be able to write utf8 to our buffer
	set s to s & "sys.stdout.write(toAppleScript(json.loads(sys.stdin.read())).encode('utf8'))"
	-- AppleScript translates new lines in old mac returns so we need to turn that off
	set appleCode to do shell script "echo " & quoted form of value & "  |python2.7 -c  " & quoted form of s without altering line endings
	set s to "on run {json}" & return
	set s to s & appleCode & return
	set s to s & "end"
	return (run script s with parameters {me})
end decodeWithDicts

on decode(value)
	set s to "import json, sys, codecs" & return
	set s to s & "sys.stdin = codecs.getreader('utf8')(sys.stdin)" & return
	set s to s & "def toAppleScript(pythonValue):" & return
	set s to s & "    output = ''" & return
	set s to s & "    if(pythonValue == None):" & return
	set s to s & "        output += 'null'" & return
	set s to s & "    elif (isinstance(pythonValue, dict)):" & return
	set s to s & "        output += '{'" & return
	set s to s & "        first = True" & return
	set s to s & "        for (key, value) in pythonValue.iteritems():" & return
	set s to s & "            if first:" & return
	set s to s & "                first = False" & return
	set s to s & "            else:" & return
	set s to s & "                output += ','" & return
	set s to s & "            output += key + ':' " & return
	set s to s & "            output += toAppleScript(value)" & return
	set s to s & "        output += '}'" & return
	set s to s & "    elif (isinstance(pythonValue, list)):" & return
	set s to s & "        output += '{'" & return
	set s to s & "        first = True" & return
	set s to s & "        for value in pythonValue:" & return
	set s to s & "            if first:" & return
	set s to s & "                first = False" & return
	set s to s & "            else:" & return
	set s to s & "                output += ','" & return
	set s to s & "            output += toAppleScript(value)" & return
	set s to s & "        output += '}'" & return
	set s to s & "    elif(isinstance(pythonValue, basestring)):" & return
	set s to s & "        output += '\"' + pythonValue.replace('\"', '\\\\\"') + '\"'" & return
	set s to s & "    else:" & return
	set s to s & "        output += json.dumps(pythonValue)" & return
	set s to s & "    return output" & return
	-- sys.stdout to be able to write utf8 to our buffer
	set s to s & "sys.stdout.write(toAppleScript(json.loads(sys.stdin.read())).encode('utf8'))"
	-- AppleScript translates new lines in old mac returns so we need to turn that off
	set appleCode to do shell script "echo " & quoted form of value & "  |python2.7 -c  " & quoted form of s without altering line endings
	set s to "on run " & return
	set s to s & appleCode & return
	set s to s & "end"
	return (run script s)
end decode

on encode(value)
	set type to class of value
	if type = integer or type = real then
		return replaceString(value as text, ",", ".")
	else if type = text then
		return encodeString(value)
	else if type = list then
		if listContainsRecord(value) then
			return encodeRecord(value)
		else
			return encodeList(value)
		end if
	else if type = script then
		return value's toJson()
	else if type = record then
		return encodeRecord(value)
	else if type = class and (value as text) = "null" then
		return "null"
	else
		error "Unknown type " & type
	end if
end encode

on listContainsRecord(value)
	repeat with element in value
		set type to class of element
		if type = list then
			if listContainsRecord(element) then
				return true
			end if
		else if type = record then
			return true
		end if
	end repeat
	return false
end listContainsRecord

on encodeList(value_list)
	set out_list to {}
	repeat with value in value_list
		copy encode(value) to end of out_list
	end repeat
	return "[" & join(out_list, ", ") & "]"
end encodeList


on encodeString(value)
	set rv to ""
	repeat with ch in value
		if id of ch = 34 or id of ch = 92 then
			set quoted_ch to "\\" & ch
		else if id of ch � 32 and id of ch < 127 then
			set quoted_ch to ch
		else if id of ch < 65536 then
			set quoted_ch to "\\u" & hex4(id of ch)
		else
			set v to id of ch
			set v_ to v - 65536
			set vh to v_ / 1024
			set vl to v_ mod 1024
			set w1 to 55296 + vh
			set w2 to 56320 + vl
			set quoted_ch to "\\u" & hex4(w1) & "\\u" & hex4(w2)
		end if
		set rv to rv & quoted_ch
	end repeat
	return "\"" & rv & "\""
end encodeString

on join(value_list, delimiter)
	set original_delimiter to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiter
	set rv to value_list as text
	set AppleScript's text item delimiters to original_delimiter
	return rv
end join

on replaceString(theText, oldString, newString)
	set AppleScript's text item delimiters to oldString
	set tempList to every text item of theText
	set AppleScript's text item delimiters to newString
	set theText to the tempList as string
	set AppleScript's text item delimiters to ""
	return theText
end replaceString


on hex4(n)
	set digit_list to "0123456789abcdef"
	set rv to ""
	repeat until length of rv = 4
		set digit to (n mod 16)
		set n to (n - digit) / 16 as integer
		set rv to (character (1 + digit) of digit_list) & rv
	end repeat
	return rv
end hex4


on createDictWith(item_pairs)
	set item_list to {}
	
	script Dict
		on setValue(key, value)
			set i to 1
			set C to count item_list
			repeat until i > C
				set kv to item i of item_list
				if item 1 of kv = key then
					set item 2 of kv to value
					set item i of item_list to kv
					return
				end if
				set i to i + 1
			end repeat
			copy {key, value} to end of item_list
		end setValue
		
		on toJson()
			set item_strings to {}
			repeat with kv in item_list
				set key_str to encodeString(item 1 of kv)
				set value_str to encode(item 2 of kv)
				copy key_str & ": " & value_str to end of item_strings
			end repeat
			return "{" & join(item_strings, ", ") & "}"
		end toJson
		
		on getValue(key)
			repeat with kv in item_list
				if item 1 of kv = key then
					return item 2 of kv
				end if
			end repeat
			error "No such key " & key & " found."
		end getValue
		
		on toRecord()
			return decode(toJson())
		end toRecord
	end script
	
	repeat with pair in item_pairs
		Dict's setValue(item 1 of pair, item 2 of pair)
	end repeat
	
	return Dict
end createDictWith

on createDict()
	return createDictWith({})
end createDict

on recordToString(aRecord)
	try
		set type to class of aRecord
		--This ensures applescript knows about the type
		if class of aRecord = list then
			set aRecord to aRecord as list
		else
			set aRecord to aRecord as record
		end if
		set aRecord to aRecord
		set str to aRecord as text
	on error errorMsg
		set startindex to 1
		set eos to length of errorMsg
		repeat until startindex is eos
			if character startindex of errorMsg = "{" then
				exit repeat
			end if
			set startindex to startindex + 1
		end repeat
		set endindex to eos
		repeat until endindex is 1
			if character endindex of errorMsg = "}" then
				exit repeat
			end if
			set endindex to endindex - 1
		end repeat
		set str to ((characters startindex thru endindex of errorMsg) as string)
		if startindex < endindex then
			return str
		end if
	end try
	set oldClipboard to the clipboard
	set the clipboard to {aRecord}
	set str to (do shell script "osascript -s s -e 'the clipboard as record'")
	set the clipboard to oldClipboard
	set str to ((characters 8 thru -1 of str) as string)
	set str to ((characters 1 thru -3 of str as string))
	return str
end recordToString

on encodeRecord(value_record)
	-- json can be used to escape a string for python
	set strRepr to recordToString(value_record)
	set s to "import json, token, tokenize, sys, codecs" & return
	set s to s & "from StringIO import StringIO" & return
	set s to s & "sys.stdin = codecs.getreader('utf8')(sys.stdin)" & return
	set s to s & "def appleScriptNotationToJSON (in_text):" & return
	set s to s & "    tokengen = tokenize.generate_tokens(StringIO(in_text).readline)" & return
	set s to s & "    depth = 0" & return
	set s to s & "    opstack = []" & return
	set s to s & "    result = []" & return
	set s to s & "    for tokid, tokval, _, _, _ in tokengen:" & return
	set s to s & "        if (tokid == token.NAME):" & return
	set s to s & "            if tokval not in ['true', 'false', 'null', '-Infinity', 'Infinity', 'NaN']:" & return
	set s to s & "                tokid = token.STRING" & return
	set s to s & "                tokval = u'\"%s\"' % tokval" & return
	set s to s & "        elif (tokid == token.STRING):" & return
	set s to s & "            if tokval.startswith (\"'\"):" & return
	set s to s & "                tokval = u'\"%s\"' % tokval[1:-1].replace ('\"', '\\\\\"')" & return
	set s to s & "        elif (tokid == token.OP) and ((tokval == '}') or (tokval == ']')):" & return
	set s to s & "            if (len(result) > 0) and (result[-1][1] == ','):" & return
	set s to s & "                result.pop()" & return
	set s to s & "            tokval = '}' if result[opstack[-1]][1] == '{' else ']'" & return
	set s to s & "            opstack.pop()" & return
	set s to s & "        elif (tokid == token.OP) and (tokval == '{' or tokval == ']'):" & return
	set s to s & "            tokval = '['" & return
	set s to s & "            opstack.append(len(result))" & return
	set s to s & "        elif (tokid == token.OP) and (tokval == ':') and result[opstack[-1]][1] != '}':" & return
	set s to s & "            result[opstack[-1]] = (result[opstack[-1]][0], '{')" & return
	set s to s & "        elif (tokid == token.STRING):" & return
	set s to s & "            if tokval.startswith (\"'\"):" & return
	set s to s & "                tokval = u'\"%s\"' % tokval[1:-1].replace ('\"', '\\\\\"')" & return
	set s to s & "        result.append((tokid, tokval))" & return
	set s to s & "    return tokenize.untokenize(result)" & return
	set s to s & "print json.dumps(json.loads(appleScriptNotationToJSON(sys.stdin.read())))" & return
	return (do shell script "echo " & quoted form of strRepr & "  | python2.7 -c  " & quoted form of s)
end encodeRecord

set aList to {}
set dict3 to �
	{glossary:�
		{GlossDiv:�
			{GlossList:�
				{GlossEntry:�
					{GlossDef:�
						{GlossSeeAlso:�
							["GML", "XML"], para:"A 'meta-markup language, used to create markup languages such as DocBook."} �
							, GlossSee:"markup", Acronym:"SGML", GlossTerm:"Standard Generalized Markup Language", Abbrev:"ISO 8879:1986", SortAs:"SGML", id:�
						"SGML"} �
						}, title:"S"} �
				, title:"example glossary"} �
			}
repeat 100 times
	set end of aList to dict3
end repeat
set startTime to (get current date)
encode(aList)
set endTime to (get current date)
set duration to endTime - startTime
log duration

set startTime to (get current date)
encode({aList:aList})
set endTime to (get current date)
set duration to endTime - startTime
log duration