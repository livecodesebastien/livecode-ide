﻿script "revInspectorBehavior"
constant kMaxLabelSize = 200

# The inspector data
local sDataA

on setAsBehavior pTarget
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of this me
   set the behavior of pTarget to the long id of this me
end setAsBehavior

setProp inspectorData pDataA
   put pDataA into sDataA
   inspectorChanged
end inspectorData

getProp inspectorData
   return sDataA
end inspectorData

before openStack
   # Open all the editors
   local tEditorsFolder, tStackFiles
   set the itemdel to "/"
   put item 1 to -3 of the filename of this me & "/inspector/editors/" into tEditorsFolder	
   revIDEPushDefaultFolder tEditorsFolder
   set the itemdel to "."
   repeat for each line tFile in the files
      if char 1 of tFile is "." then next repeat
      
      if tStackfiles is empty then
         put item 1 to -2 of tFile &comma&tEditorsFolder&tFile into tStackFiles
      else
         put return & item 1 to -2 of tFile &comma& tEditorsFolder&tFile after tStackFiles
      end if
   end repeat
   set the stackfiles of me to tStackFiles
   revIDEPopDefaultFolder
end openStack

on resizeInspector
   lock screen
   inspectorLayout
   unlock screen
end resizeInspector

constant kInspectorMinHeight = 200
constant kInspectorMinWidth = 220
on inspectorOpenEditor pEditor
   # Check if the stack is already open
   if there is a stack pEditor then exit inspectorOpenEditor
   
   # Find the file for the editor
   local tEditorStackPath, tEditorBehaviorPath
   put revIDEPaletteResourcePath("editors/" & pEditor & ".livecode") into tEditorStackPath
   put revIDEPaletteResourcePath("editors/" & pEditor & ".behavior.livecodescript") into tEditorBehaviorPath
   # open editor stack if it exists
   if there is a file tEditorStackPath then 
      go invisible stack tEditorStackPath
   end if
   
   if there is a file tEditorBehaviorPath then 
      go invisible stack tEditorBehaviorPath
   end if
end inspectorOpenEditor

# Layout inspector
on inspectorLayout
   //put "layout inspector" & return after msg
   lock screen
   
   # Get the section of the PI we should be laying out
   local tSelectedGroup
   put inspectorSectionGet() into tSelectedGroup
   
   inspectorLayoutGroups sDataA[tSelectedGroup]["grouplist"]
   unlock screen
end inspectorLayout

on inspectorLayoutGroups pGroupList
   lock screen
   # Get the margin, padding
   local tMargin, tPadding
   put the paletteMargin of me into tMargin
   put the palettePadding of me into tPadding
   
   # Get layout key points
   local tTop, tLeft, tContentRect
   put the contentRect of me into tContentRect
   put item 1 of tContentRect + tMargin into tLeft
   put item 2 of tContentRect + tMargin into tTop
   
   # Loop through the editors and get the minimum width of the labels and editors
   # To work out an initial row width
   local tMinRowWidth, tMinEditorsWidth, tRowWidth, tMinLabelWidth
   repeat for each element tElement in pGroupList
      if there is not a group tElement["label"] of me then next repeat
      local tEditorsReportedWidth, tLabelReportedWidth
      put the rowMinWidth of group tElement["label"] of me into tEditorsReportedWidth
      put the rowLabelWidth of group tElement["label"] of me into tLabelReportedWidth
      
      if tEditorsReportedWidth > tMinEditorsWidth then
         put tEditorsReportedWidth into tMinEditorsWidth
      end if
      if tLabelReportedWidth > tMinLabelWidth then
         put tLabelReportedWidth into tMinLabelWidth
      end if
   end repeat
   put tMinEditorsWidth + tMinLabelWidth  into tMinRowWidth 
   put tMinRowWidth into tRowWidth
   
   # Next, check the width of the stack as it stands.
   if the width of me - (tMargin * 2) > tRowWidth then
      put the width of me - (tMargin * 2) into tRowWidth
   end if
   
   # Don't let the inspector get any smaller than kInspectorMinWidth
   if tMinRowWidth + (tMargin * 2) < kInspectorMinWidth then
      put kInspectorMinWidth - (tMargin * 2) into tMinRowWidth
   end if
   
   # Get the stored width for the inspector to update calculated width. If stored width is larger,
   # used stored width as width of editor
   
   local tInspectorWidthWithMargins
   put tRowWidth + (tMargin  * 2) into tInspectorWidthWithMargins
   
   local tSubsections, tCurSection, tNewSubsection
   # Check if this inspector wants to show subsections
   put the showSubSections of me into tSubsections
   
   local tMaxRowWidth, tInspectorHeight, tColumnNumber, tColumnTop
   put 1 into tColumnNumber
   repeat for each element tElement in pGroupList
      if tSubsections and tElement["subsection"] is not empty then
         # If we have a new subsection, create the subsection header
         if tElement["subsection"] is not tCurSection then
            lock messages
            set the width of group ("Subsection_" & tElement["subsection"]) of me to the formattedwidth of field tElement["subsection"] of group ("Subsection_" & tElement["subsection"]) of me
            set the width of field tElement["subsection"] of group ("Subsection_" & tElement["subsection"]) of me to the formattedwidth of field tElement["subsection"] of group ("Subsection_" & tElement["subsection"]) of me
            set the topleft of group ("Subsection_" & tElement["subsection"]) of me to tLeft,tTop
            unlock messages
            add (the formattedheight of field tElement["subsection"] of group ("Subsection_" & tElement["subsection"]) of me) to tTop
            put tElement["subsection"] into tCurSection
         end if
      end if
      
      if there is a group tElement["label"] of me then
         # set the width and topleft of the editor
         lock messages
         set the topleft of group tElement["label"] of me to tLeft,tTop
         set the lockloc of  group tElement["label"] of me to true
         set the width of group tElement["label"] of me to tRowWidth
         unlock messages
         
         # Tell the row to resize
         dispatch "rowResize" to group tElement["label"] of me
         
         local tEditorHeight
         # If the editor does not report its own height, use the formatted height
         # This tends to report slightly strange values, otherwise we could just use it
         # all the time.
         put the editorHeight of group tElement["label"] of me into tEditorHeight
         if not tEditorHeight > 0 then
            put the formattedheight of group tElement["label"] of me into tEditorHeight
         end if
         
         lock messages
         add tEditorHeight + tPadding to tTop
         
         if tRowWidth > tMaxRowWidth then
            put tRowWidth into tMaxRowWidth
         end if
         if tTop > tInspectorHeight then
            put tTop into tInspectorHeight
         end if
         unlock messages
      end if
   end repeat
   
   local tStackTop, tStackLeft
   put the top of me into tStackTop
   put the left of me into tStackLeft
   
   
   if there is a field "noObjects" of me then
      set the width of field "noObjects" of me to 1000
      put the formattedWidth of field "noObjects" of me into tMinRowWidth
      set the height of field "noObjects" of me to the formattedHeight of field "noObjects" of me
      set the width of field "noObjects" of me to the formattedWidth of field "noObjects" of me
      set the loc of field "noObjects" of me to the loc of this card
   end if
   
   lock messages
   
   if the minWidth of me < tMinRowWidth + (tMargin*2) then
      set the minWidth of me to tMinRowWidth + (tMargin*2)
   end if
   
   if the width of me < max(tInspectorWidthWithMargins, the minWidth of me) then
      set the width of me to max(tInspectorWidthWithMargins, the minWidth of me)
      layoutFrame
   end if
   
   set the left of me to tStackLeft
   
   local tStackHeight
   if tInspectorHeight is empty then
      put kInspectorMinHeight into tStackHeight
   else
      put tInspectorHeight + tMargin into tStackHeight
   end if
   
   set the minheight of me to tStackHeight
   set the maxheight of me to tStackHeight
   set the height of me to tStackHeight
   set the top of me to tStackTop
   
   unlock messages
   unlock screen
end inspectorLayoutGroups

local sSelectedSection, sSelectedSectionIndex
private on inspectorSectionSet pSection
   if sDataA is empty then
      put empty into sSelectedSection
      put 0 into sSelectedSectionIndex
      exit inspectorSectionSet
   end if
   
   local tIndex
   put inspectorSectionIndex(pSection) into tIndex
   
   if tIndex is 0 then
      # AL-2015-06-23: [[ Bug ]] If the selected section doesn't exist for the 
      # newly inspected object then use the default (first) section
      put sDataA[1]["label"] into pSection
      put 1 into tIndex
   end if
   
   if tIndex is not sSelectedSectionIndex or pSection is not sSelectedSection then
      put pSection into sSelectedSection
      put tIndex into sSelectedSectionIndex
      dispatch "hiliteFrameItem" to me with sSelectedSection
      dispatch "navSelected" to me with sSelectedSection
   end if
end inspectorSectionSet

private function inspectorSectionGet
   return sSelectedSectionIndex
end inspectorSectionGet

private function inspectorSectionIndex pSection
   repeat for each key tIndex in sDataA
      if sDataA[tIndex]["label"] is pSection then
         return tIndex
      end if
   end repeat
   
   return 0
end inspectorSectionIndex

function inspectorSectionGetName
   if sSelectedSection is not empty then 
      return sSelectedSection
   else
      return sDataA[1]["label"]
   end if
end inspectorSectionGetName

private function inspectorDontShowGroup pGroup
   repeat for each element tProperty in pGroup["proplist"]
      if tProperty["user_visible"] is true then
         return false
      end if
   end repeat
   return true
end inspectorDontShowGroup

# Generate inspector
private on inspectorGenerate
   if sSelectedSection is empty then
      inspectorSectionSet sDataA[1]["label"]
   else
      inspectorSectionSet sSelectedSection
   end if
   
   local tPropertyData
   put sDataA[sSelectedSectionIndex] into tPropertyData
   
   if tPropertyData is empty then
      inspectorNoObject
   else
      inspectorGenerateGroups tPropertyData["grouplist"]
   end if
end inspectorGenerate

private command inspectorNoObject
   create group "noObjects"
   create field "noObjects" in group "noObjects"
   set the text of it to "No object selected"
   set the opaque of it to false
   set the showborder of it to false 
   set the textSize of it to 24
   set the textAlign of it to "center"
   set the themeClass of it to "label"
   set the lockText of it to true
   set the traversalOn of it to false
end inspectorNoObject

on inspectorGenerateGroups pGroupList
   lock screen
   set the margins of the templategroup to 0
   set the visible of the templategroup to false
   
   local tStackPath
   set the behavior of the templategroup to the long ID of stack revIDEPaletteResourcePath("behaviors/revinspectorgroupbehavior.livecodescript", the long ID of stack "revInspector")
   
   set the traversalon of the templatefield to false
   set the threed of the templatefield to false
   set the showborder of the templatefield to false
   set the showfocusborder of the templatefield to false
   set the textalign of the templatefield to right
   set the opaque of the templatefield to false
   set the height of the templatefield to 22
   set the locktext of the templatefield to true
   set the width of the templatefield to kMaxLabelSize
   
   lock messages
   if there is not a group "template" then
      create group "template"
      create field "rowlabel" in group "template"
      set the topleft of field "rowlabel" of group "template" to the topleft of group "template"
   end if
   unlock messages
   
   local tSubsections
   put the showSubSections of me into tSubsections
   
   local tElement
   repeat with x = 1 to the number of elements in pGroupList
      put pGroupList[x] into tElement
      if tElement["label"] is empty then next repeat
      
      # If none of the properties is user visible then skip the group
      if inspectorDontShowGroup(tElement) then
         next repeat
      end if
      
      if tSubsections and tElement["subsection"] is not empty then
         if there is not a group ("Subsection_" & tElement["subsection"]) of me then
            create group "Subsection_" & tElement["subsection"]
            show it
            create field tElement["subsection"] in it
            set the text of it to tElement["subsection"]
            set the textstyle["bold"] of it to true
            set the textstyle["underline"] of it to true
         end if
      end if
      
      lock messages
      copy group "template" to me
      set the name of it to tElement["label"]
      show group tElement["label"] of me
      unlock messages
      set the rowShowLabel of group tElement["label"] of me to true
      
      local tName
      put the short name of group tElement["label"] of me into tName
      if exists(group tElement["label"] of me) then
         local tPropList, tProperty
         repeat with y = 1 to the number of elements in tElement["proplist"]
            put tElement["proplist"][y] into tProperty
            if tProperty["user_visible"] is false then next repeat
            dispatch "propertyRegister" to group tElement["label"] of me with tProperty
            
            # Build the list of properties to display in the tooltip for the row
            if tPropList is empty then
               put tProperty["property_name"] into tPropList
            else
               put return & tProperty["property_name"] after tPropList
            end if
         end repeat
         
         # Set the tooltip and label for the row according to 'language names' pref
         global gRevLanguageNames
         local tTooltip, tLabel
         if gRevLanguageNames then
            put tPropList into tLabel
            put tElement["label"] into tTooltip
         else
            put tPropList into tTooltip
            put tElement["label"] into tLabel
         end if
         
         set the rowTooltip of group tElement["label"] of me to tTooltip
         if tElement["label"] is not tElement["subsection"] then
            set the rowLabel of group tElement["label"] of me to tLabel
         end if
      end if
      put empty into tPropList
   end repeat
   reset the templatefield
   reset the templategroup
   
   unlock screen
end inspectorGenerateGroups

private on inspectorNavigationGenerate
   lock screen
   # Clear the current frame data
   clearFrameData
   
   # Add all the navigation elements
   repeat with x = 1 to the number of elements in sDataA
      local tSection
      put sDataA[x] into tSection
      
      local tIcon
      dispatch function "inspectorSectionIcon" to me with tSection["label"]
      put the result into tIcon
      addFrameItem tSection["label"],"header", "navigation", tSection["label"], tIcon, tIcon, "inspectorSectionChanged", the long id of me, tSection["label"]
   end repeat
   
   dispatch "inspectorAddActions" to me
   unlock screen
end inspectorNavigationGenerate

on inspectorChanged
   lock screen
   # Clear any transient text field
   revIDEDismissTransient
   
   # Clear the current inspector
   inspectorClear
   
   # Generate the frame
   inspectorNavigationGenerate
   generateFrame
   
   # Generate the controls for group
   inspectorGenerate
   
   # Set values for all editors
   inspectorFill
   
   # Layout
   inspectorLayout
   
   unlock screen
end inspectorChanged

# Sent when the user changes the section
on inspectorSectionChanged pSection
   # Check if the section is different
   if inspectorSectionGetName() is pSection then exit inspectorSectionChanged
   
   # Update an editor in case it has changed
   updateFocusedEditor
   
   # Set the section
   inspectorSectionSet pSection
   
   inspectorChanged
end inspectorSectionChanged

on updateFocusedEditor
   if revIDEStackOfObject(the focusedObject) is the long name of me then
      # Ensure that if the text of a field was changed, the value is set when changing sections
      # Using focus on nothing makes sure the correct message is sent (closeField / exitField)
      focus on nothing
   end if
end updateFocusedEditor

on inspectorFill
   lock screen
   
   # Store the selected chunk if:
   # 1) There is a focused object
   # 2) The focused object is on the inspector stack
   
   local tSelectedChunk
   if the focusedobject is not empty then
      if revIDEStackOfObject(the focusedobject) is the long name of me then
         if the selectedfield is not empty and not the listBehavior of the selectedField then
            put the selectedfield && "of stack" && quote & the short name of me & quote into tSelectedChunk
         end if
      end if
   end if
   
   local tProperties
   put the displayData of me into tProperties
   
   inspectorFillGroups tProperties
   
   # Restore the selected chunk if it exists
   if tSelectedChunk is not empty and exists(tSelectedChunk) then
      lock messages
      select char 1 to -1 of tSelectedChunk
      unlock messages
   end if
   
   unlock screen
end inspectorFill

on inspectorFillGroups pGroupData
   local tRow
   repeat for each key tRow in pGroupData
      if there is a group tRow of me then
         set the rowData of group tRow of me to pGroupData[tRow]
      end if
   end repeat
end inspectorFillGroups

on inspectorClear
   if the number of groups of card 1 of me is 0 then
      exit inspectorClear
   end if
   
   lock screen
   lock messages
   repeat while the number of groups of card 1 of me is not 1
      if the short name of group 2 of me is "background" then
         delete group 1 of card 1 of me
      else
         dispatch "rowFinalize" to group 2 of card 1 of me
         delete group 2 of card 1 of me
      end if
   end repeat
   
   rowLabelWidthSet 0
   unlock messages
   unlock screen
end inspectorClear

#####################
#### PROPERTIES #####
#####################

# Whether or not we display labels or 
on inspectorLabelTypeSet pType
   # Check if the value has changed
   
   # Repeat through the rows and set the label to the right value
   
   # Layout to adjust the width of the labels
end inspectorLabelTypeSet

function inspectorLabelTypeGet 
   # Return the label type
end inspectorLabelTypeGet

local sRowLabelWidth
function rowlabelWidth
   if sRowLabelWidth <= 0 then
      put rowLabelWidthCalculate() into sRowLabelWidth
   end if
   return sRowLabelWidth
end rowlabelWidth

on rowLabelWidthSet pValue
   put pValue into sRowLabelWidth
end rowLabelWidthSet

private function rowLabelWidthCalculate
   local tMaxWidth, tLabelWidth, tChildren
   put 0 into tMaxWidth
   
   put the childControlNames of this card of me into tChildren
   repeat for each line tControl in tChildren
      if there is a field "rowlabel" of group tControl of me then
         put the rowLabelWidth of group tControl of me into tLabelWidth
      end if
      if tLabelWidth > tMaxWidth then
         put tLabelWidth into tMaxWidth
      end if
   end repeat
   return tMaxWidth
end rowLabelWidthCalculate

# Allow text to be styled from the menubar if the editor allows it
on ideStyleTextRequest pWhich, pValue, pSelectedChunk, pSelectedObject
   if word 1 of pSelectedObject is "field" and the owner of pSelectedObject is not empty then
      local tOwner
      put the long id of the owner of pSelectedObject into tOwner
      if the short name of tOwner is "styledText" then
         ideStyleText pSelectedChunk, pSelectedObject, true, pWhich, pValue
         dispatch "valueChanged" to tOwner
      end if
   end if
end ideStyleTextRequest
