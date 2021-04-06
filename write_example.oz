functor
import
   Open
define
	local
		Filename = stdout
		OutputFile		
		WriteListToFile
		ExampleList
	in
		proc {WriteListToFile L F}
	 		% F must be an opened file
	 		case L
	 		of H|nil then
				{F write(vs:H)}
	 		[]H|T then
				{F write(vs:H#",")}
				{WriteListToFile T F}
	 		end
    end
		%% change filename to atom stdout to write to the standard output
		OutputFile = {New Open.file init(name: Filename
						flags: [write create truncate text])}
		ExampleList = ["Harry Potter" "Hermione Granger" "Ron Weasley"]
	
		{WriteListToFile ExampleList OutputFile}
		{OutputFile close}
	end
end
