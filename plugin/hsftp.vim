
" Title: hsftp
" Description: Upload and download files through sftp
" Usage: :Hupload and :Hdownload
"        By default mapped to
"        <leader>hsd (hsftp download) and
"        <leader>hsu (hsftp upload)
"        See README for more
" Github: https://github.com/hesselbom/vim-hsftp
" Author: Viktor Hesselbom (hesselbom.net)
" License: MIT

function! H_GetConf()
	let conf = {}

	let l_configpath = expand('%:p:h')
	let l_configfile = l_configpath . '/.hsftp'
	let l_foundconfig = ''
	if filereadable(l_configfile)
		let l_foundconfig = l_configfile
	else
		while !filereadable(l_configfile)
			let slashindex = strridx(l_configpath, '/')
			if slashindex >= 0
				let l_configpath = l_configpath[0:slashindex]
				let l_configfile = l_configpath . '.hsftp'
				let l_configpath = l_configpath[0:slashindex-1]
				if filereadable(l_configfile)
					let l_foundconfig = l_configfile
					break
				endif
				if slashindex == 0 && !filereadable(l_configfile)
					break
				endif
			else
				break
			endif
		endwhile
	endif

	if strlen(l_foundconfig) > 0
		let options = readfile(l_foundconfig)
		for i in options
			let vname = substitute(i[0:stridx(i, ' ')], '^\s*\(.\{-}\)\s*$', '\1', '')
			let vvalue = escape(substitute(i[stridx(i, ' '):], '^\s*\(.\{-}\)\s*$', '\1', ''), "%#!")
			let conf[vname] = vvalue
		endfor

		let conf['local'] = fnamemodify(l_foundconfig, ':h:p') . '/'
		let conf['localpath'] = expand('%:p')
		let conf['remotepath'] = conf['remote'] . conf['localpath'][strlen(conf['local']):]
	endif

	return conf
endfunction

function! H_Finished(channel)
	echo 'Done!'
endfunction

function! H_OnUploadEvent(job_id, data, event) dict
	if a:event == 'stderr'
		echom '[❌] Upload error.'
	else
		echom '[✓] Finished uploading!'
	endif
endfunction

function! H_DiffRemote()
	let conf = H_GetConf()

	if has_key(conf, 'host')
		let cmd = printf('diffsplit scp://%s@%s/%s|windo wincmd H', conf['user'], conf['host'], conf['remotepath'])
		silent execute cmd
	endif
endfunction
function! H_DownloadFile()
	let conf = H_GetConf()

	if has_key(conf, 'host')
		let cmd = printf('1,$d|0Nr "sftp://%s@%s/%s"', conf['user'], conf['host'], conf['remotepath'])
		echo printf('Downloading %s from %s...', conf['remotepath'], conf['host'])
		silent execute cmd
		echo 'Done! Saving...'
		silent execute 'w'
	endif
endfunction

function! H_UploadFile()
	let conf = H_GetConf()

	if has_key(conf, 'host')
		" let cmd = printf('Nw "sftp://%s@%s/%s"', conf['user'], conf['host'], conf['remotepath'])
		echo printf('Start uploading %s...', conf['localpath'])
		let cmd = printf('rsync -az %s %s@%s:%s', conf['localpath'], conf['user'], conf['host'], conf['remotepath'])
		" silent execute cmd
		call jobstart(cmd, {'on_stderr': function('H_OnUploadEvent'), 'on_exit': function('H_OnUploadEvent')})
	endif
endfunction

command! Hdiff call H_DiffRemote()
command! Hdownload call H_DownloadFile()
command! Hupload call H_UploadFile()

nmap <leader>hsd :Hdownload<CR>
nmap <leader>hsu :Hupload<CR>
