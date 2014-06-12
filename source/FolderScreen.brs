'**********************************************************
'** createFolderScreen
'**********************************************************

Function createFolderScreen(viewController as Object, item as Object) As Object

	parentId = item.Id
	title = item.Title

	if item.ContentType = "BoxSet" then
		settingsPrefix = "movie"
		contextMenuType = invalid
	else
		settingsPrefix = "mediaFolders"
		contextMenuType = "mediaFolders"
	End if

    imageType      = (firstOf(RegUserRead(settingsPrefix + "ImageType"), "0")).ToInt()

	names = [item.Title]
	keys = [item.Id]

	loader = CreateObject("roAssociativeArray")
	loader.settingsPrefix = settingsPrefix
	loader.contentType = item.ContentType
	loader.getUrl = getFolderItemsUrl
	loader.parsePagedResult = parseFolderItemsResult

    if imageType = 0 then
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "mixed-aspect-ratio")
    else
        screen = createPaginatedGridScreen(viewController, names, keys, loader, "two-row-flat-landscape-custom")
    end if

	screen.baseActivate = screen.Activate
	screen.Activate = folderScreenActivate

	screen.settingsPrefix = settingsPrefix

	screen.contextMenuType = contextMenuType
    screen.displayInfoBox = (firstOf(RegUserRead(settingsPrefix + "InfoBox"), "0")).ToInt()

	screen.createContextMenu = folderScreenCreateContextMenu

    return screen
End Function

Sub folderScreenActivate(priorScreen)

    imageType      = (firstOf(RegUserRead(m.settingsPrefix + "ImageType"), "0")).ToInt()
	displayInfoBox = (firstOf(RegUserRead(m.settingsPrefix + "InfoBox"), "0")).ToInt()
	
    if imageType = 0 then
		gridStyle = "mixed-aspect-ratio"
    Else
		gridStyle = "two-row-flat-landscape-custom"
    End If

	m.baseActivate(priorScreen)

	if gridStyle <> m.gridStyle or displayInfoBox <> m.displayInfoBox then
		
		m.displayInfoBox = displayInfoBox
		m.gridStyle = gridStyle
		m.DestroyAndRecreate()

	end if

End Sub

Function getFolderItemsFilter(settingsPrefix as String, contentType as String) as Object

    filterBy       = (firstOf(RegUserRead(settingsPrefix + "FilterBy"), "0")).ToInt()
    sortBy         = (firstOf(RegUserRead(settingsPrefix + "SortBy"), "0")).ToInt()
    sortOrder      = (firstOf(RegUserRead(settingsPrefix + "SortOrder"), "0")).ToInt()

    mediaFoldersFilter = {}

    if filterBy = 1
        mediaFoldersFilter.AddReplace("Filters", "IsUnPlayed")
    else if filterBy = 2
        mediaFoldersFilter.AddReplace("Filters", "IsPlayed")
    end if

	' Just take the default sort order for collections
	if contentType <> "BoxSet" then
		if sortBy = 1
			mediaFoldersFilter.AddReplace("SortBy", "DateCreated,SortName")
		else if sortBy = 2
			mediaFoldersFilter.AddReplace("SortBy", "DatePlayed,SortName")
		else if sortBy = 3
			mediaFoldersFilter.AddReplace("SortBy", "PremiereDate,SortName")
		else
			mediaFoldersFilter.AddReplace("SortBy", "SortName")
		end if

		if sortOrder = 1
			mediaFoldersFilter.AddReplace("SortOrder", "Descending")
		end if
	end if

	return mediaFoldersFilter

End Function

Function getFolderItemsUrl(row as Integer, id as String) as String

    ' URL
    url = GetServerBaseUrl() + "/Users/" + HttpEncode(getGlobalVar("user").Id) + "/Items?parentid=" + id

    query = {
        fields: "Overview,UserData"
    }

	filters = getFolderItemsFilter(m.settingsPrefix, m.contentType)

    if filters <> invalid
        query = AddToQuery(query, filters)
    end if

	for each key in query
		url = url + "&" + key +"=" + HttpEncode(query[key])
	end for

    return url

End Function

Function parseFolderItemsResult(row as Integer, json as String) as Object

	imageType      = (firstOf(RegUserRead("mediaFoldersImageType"), "0")).ToInt()
	
    return parseItemsResponse(json, imageType, "mixed-aspect-ratio-portrait")

End Function

Function folderScreenCreateContextMenu()
	
	if m.contextMenuType <> invalid then
		createContextMenuDialog(m.contextMenuType)
	end if

	return true

End Function
