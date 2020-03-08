#!/usr/bin/osascript

property tagName : "Randomizer"
set theResult to {}

tell application "OmniFocus"
	tell default document
		set theTag to (first flattened tag whose name is tagName)
		tell theTag
			repeat with theTask in (tasks)
				set theResult to theResult & {name of theTask}
			end repeat
		end tell
	end tell
end tell

set resultTask to some item of theResult

display notification with title "Task Randomizer" subtitle resultTask

copy ("Result : " & resultTask) to stdout
