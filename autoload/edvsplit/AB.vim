" Author: lymslive
" Create: 2016-03-8
" Last Modify: 2017-08-11
"

" Ignore some extensions
let s:wildignore_default = "*.o,*.obj,*.out,*.exe"

" Find a alternative file in one path.
" IN: a:file, filename without path
"     a:path, path name where to find
" OUT:
"     the first file with same filename but different extension,
"     or just filename without any extension.
function! edvsplit#AB#FindAltInPath(file, path, ...) " {{{1
	let s:wildignore_saved = &wildignore
	let &wildignore = s:wildignore_default

	let filefound = ""
	if a:0 > 0 && strlen(a:1) > 0
		let extspec = a:1
	else
		let extspec = ".*"
	endif

	let basename = fnamemodify(a:file, ":t:r")
	let globstring = a:path . '/' . basename . extspec
	" echomsg "glob files: " . globstring
	let gfiles = glob(globstring, 1, 1)
	if len(gfiles) > 0
		for i in range(0, len(gfiles)-1) 
			if fnamemodify(gfiles[i], ":t") !=# fnamemodify(a:file, ":t")
				let filefound = gfiles[i]
				break
			endif
		endfor
	else
		let gfiles = glob(a:path . '/' . basename, 1, 1)
		if len(gfiles) > 0
            let filefound = gfiles[0]
		endif
	endif

	let &wildignore = s:wildignore_saved
	return filefound
endfunction

" Find a altnative file in four relation places:
"  selft, child, parent, sibling (no recursion)
"
" IN/OUT argument refer to edvsplit#AB#FindAltInPath()
function! edvsplit#AB#FindAltFromPath(file, basepath, ...) " {{{1
	let filefound = ""
	let path = edvsplit#AB#ChompPathSlash(a:basepath)
	if a:0 > 0
		let extspec = a:1
	else
		let extspec = ""
	endif
	" echomsg printf("calling edvsplit#AB#FindAltFromPath(%s, %s, %s)", a:file, path, extspec)

	" Lv1: current directory
	" echomsg "lookup in current directory: "
	let filefound = edvsplit#AB#FindAltInPath(a:file, path, extspec)
	if strlen(filefound) > 0
		" echomsg "find in current directory: " . filefound
		return filefound
	endif

	" Lv2: directly sub dircetory
	" echomsg "lookup in sub directory: "
	let subpaths = edvsplit#AB#ListSubdirectory(path)
	for i in range(1, len(subpaths)-1) 
		let subpath = subpaths[i]
		" echomsg "lookup in sibling directory: " . subpath
		let filefound = edvsplit#AB#FindAltInPath(a:file, subpath, extspec)
		if strlen(filefound) > 0
			" echomsg "find in sub directory: " . filefound
			return filefound
		endif
	endfor

	" L3: parent path
	let parentpath = fnamemodify(path, ":h")
	" echomsg "lookup in parent directory: " . parentpath
	let filefound = edvsplit#AB#FindAltInPath(a:file, parentpath, extspec)
	if strlen(filefound) > 0
		" echomsg "find in parent directory: " . filefound
		return filefound
	endif

	" L4: sibling path
	" echomsg "lookup in sibling directory: "
	let sibpaths = edvsplit#AB#ListSubdirectory(parentpath)
	for i in range(1, len(sibpaths)-1) 
		let sibpath = sibpaths[i]
		" echomsg "lookup in sibling directory: " . sibpath
		if sibpath ==# path
			continue
		endif
		let filefound = edvsplit#AB#FindAltInPath(a:file, sibpath, extspec)
		if strlen(filefound) > 0
			" echomsg "find in sibling directory: " . filefound
			return filefound
		endif
	endfor

	return filefound
endfunction

" remove the last optional / or \ character in a path string
function! edvsplit#AB#ChompPathSlash(path) " {{{1
	let mpath = substitute(a:path, '[/\\]$', '', '') 
	return mpath
endfunction

" list all the subdirectory (only one deepth)
" the returned list contain the basepath itself as the first item
" refer to unix command find
function! edvsplit#AB#ListSubdirectory(basepath) " {{{1
	let subpathstring = system('find ' . a:basepath . ' -maxdepth 1 -type d')
	let subpaths = split(subpathstring, '\n')
	return subpaths
endfunction

" find a alt file, from it's path or current path
function! edvsplit#AB#FindAltFile(file, ...) " {{{1
	if a:0 > 0
		let extspec = a:1
	else
		let extspec = ""
	endif
	" echomsg printf("calling edvsplit#AB#FindAltFile(%s, %s)", a:file, extspec)

	let filefound = ""
	let basepath = fnamemodify(a:file, ":p:h")
	let filefound = edvsplit#AB#FindAltFromPath(a:file, basepath, extspec)
	if strlen(filefound) > 0
		return filefound
	endif

	if basepath !=# getcwd()
		let basepath = getcwd()
		let filefound = edvsplit#AB#FindAltFromPath(a:file, basepath, extspec)
		if strlen(filefound) > 0
			return filefound
		endif
	endif
	return filefound
endfunction

" edit the alt-file of current file
function! edvsplit#AB#EditAltFile(file, ...) " {{{1
	" let file = expand("%:p")
	if a:0 > 0
		let extspec = a:1
	else
		let extspec = ""
	endif
	let altfile = edvsplit#AB#FindAltFile(a:file, extspec)
	if strlen(altfile) > 0
		execute "edit ". altfile
	else
		echoerr "can't find alternative file"
	endif
endfunction

" Foot Note:
" comment out echomsg, add "<space>
" g/^\s*echom/ normal! I" 
