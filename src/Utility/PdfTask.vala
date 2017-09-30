/*
 * PdfTask.vala
 *
 * Copyright 2017 Tony George <teejeetech@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using GLib;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.ProcessHelper;
using TeeJee.System;
using TeeJee.Misc;

public class PdfTask : GLib.Object {

	public bool silent = false;
	 
	public PdfTask(bool _silent){
		silent = _silent;
	}

	public bool split(string file_path, bool inplace){

		if (!file_exists(file_path)){ return false; }

		if (!silent){
			log_msg("%s:  %s".printf(_("Input"), file_path));
		}
		
		string cmd = "pdftk";

		cmd += " '%s'".printf(escape_single_quote(file_path));

		cmd += " burst";
		
		string outfile = "%s_page_%%03d.pdf".printf(file_get_title(file_path));
		outfile = path_combine(file_parent(file_path), outfile);
		
		cmd += " output '%s'".printf(escape_single_quote(outfile));

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		//cmd += " compress";
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace){
			file_delete(file_path);
		}

		string doc_file = path_combine(file_parent(file_path), "doc_data.txt");
		file_delete(doc_file);

		return (std_err.strip().length == 0);
	}
	
	public bool merge(Gee.ArrayList<string> files, bool inplace){
		
		if (files.size == 0){ return false; }

		if (!silent){
			log_msg("%s:  %d file(s)".printf(_("Input"), files.size));
		}
		
		string cmd = "pdftk";

		foreach(var item in files){
			cmd += " '%s'".printf(escape_single_quote(item));
		}

		cmd += " cat";

		string title = file_get_title(files[0]);
		var match = regex_match("""^(.*?)[_]*(page)*(_)*[0-9]*(.pdf)*$""", title);
		if (match != null){
			title = match.fetch(1);
		}

		string outfile = "%s_merged.pdf".printf(title);
		outfile = path_combine(file_parent(files[0]), outfile);

		cmd += " output '%s'".printf(escape_single_quote(outfile));

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		//cmd += " compress";
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace && file_exists(outfile)){
			foreach(string file in files){
				file_delete(file);
			}
		}

		return (std_err.strip().length == 0);
	}

	public bool compress(string file_path, bool inplace){
		
		if (!file_exists(file_path)){ return false; }

		if (!silent){
			log_msg("%s:  %s".printf(_("Input"), file_path));
		}
		
		string outfile = "%s_compressed.pdf".printf(file_get_title(file_path));
		outfile = path_combine(file_parent(file_path), outfile);
		
		string cmd = "gs";
		cmd += " -sOutputFile='%s'".printf(escape_single_quote(outfile));
		cmd += " -sDEVICE=pdfwrite";
		cmd += " -dCompatibilityLevel=1.4";
		cmd += " -dDetectDuplicateImages=true";
		cmd += " -dCompressFonts=true";
		cmd += " -dPDFSETTINGS=/%s".printf("screen");
		cmd += " -dNOPAUSE";
		cmd += " -dBATCH";
		cmd += " '%s'".printf(escape_single_quote(file_path));

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace && file_exists(outfile)){
			file_delete(file_path) && file_move(outfile, file_path);
		}

		return (std_err.strip().length == 0);
	}

	public bool uncompress(string file_path, bool inplace){

		if (!file_exists(file_path)){ return false; }

		if (!silent){
			log_msg("%s:  %s".printf(_("Input"), file_path));
		}
		
		string cmd = "pdftk";

		cmd += " '%s'".printf(escape_single_quote(file_path));

		string outfile = "%s_uncompressed.pdf".printf(file_get_title(file_path));
		outfile = path_combine(file_parent(file_path), outfile);
		cmd += " output '%s'".printf(escape_single_quote(outfile));

		cmd += " uncompress";

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace && file_exists(outfile)){
			file_delete(file_path) && file_move(outfile, file_path);
		}

		return (std_err.strip().length == 0);
	}

	public bool protect(string file_path, string password, bool inplace){
		
		if (!file_exists(file_path)){ return false; }

		if (!silent){
			log_msg("%s:  %s".printf(_("Input"), file_path));
			log_msg("%s: %s".printf(_("Pass"), password));
		}
		
		string cmd = "pdftk";

		cmd += " '%s'".printf(escape_single_quote(file_path));

		string title = file_get_title(file_path);
		var match = regex_match("""^(.*)_[un]*protected$""", title);
		if (match != null){
			title = match.fetch(1);
		}
		
		string outfile = "%s_protected.pdf".printf(title);
		outfile = path_combine(file_parent(file_path), outfile);

		cmd += " output '%s'".printf(escape_single_quote(outfile));

		//cmd += " owner_pw '%s'".printf(password);

		cmd += " user_pw '%s'".printf(escape_single_quote(password));

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace && file_exists(outfile)){
			file_delete(file_path) && file_move(outfile, file_path);
		}
		
		return (std_err.strip().length == 0);
	}

	public bool unprotect(string file_path, string password, bool inplace){
		
		if (!file_exists(file_path)){ return false; }

		if (!silent){
			log_msg("%s:  %s".printf(_("Input"), file_path));
			log_msg("%s: %s".printf(_("Pass"), password));
		}
		
		string cmd = "pdftk";

		cmd += " '%s'".printf(escape_single_quote(file_path));

		cmd += " input_pw '%s'".printf(escape_single_quote(password));

		string title = file_get_title(file_path);
		var match = regex_match("""^(.*)_[un]*protected$""", title);
		if (match != null){
			title = match.fetch(1);
		}
		
		string outfile = "%s_unprotected.pdf".printf(title);
		outfile = path_combine(file_parent(file_path), outfile);

		cmd += " output '%s'".printf(escape_single_quote(outfile));

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace && file_exists(outfile)){
			file_delete(file_path) && file_move(outfile, file_path);
		}

		return (std_err.strip().length == 0);
	}

	public bool decolor(string file_path, bool inplace){

		if (!file_exists(file_path)){ return false; }

		if (!silent){
			log_msg("%s:  %s".printf(_("Input"), file_path));
		}
		
		string outfile = "%s_decolored.pdf".printf(file_get_title(file_path));
		outfile = path_combine(file_parent(file_path), outfile);
		
		string cmd = "gs";
		cmd += " -sOutputFile='%s'".printf(escape_single_quote(outfile));
		cmd += " -sDEVICE=pdfwrite";
		cmd += " -sColorConversionStrategy=Gray";
		cmd += " -dProcessColorModel=/DeviceGray";
		cmd += " -dCompatibilityLevel=1.4";
		cmd += " -dDetectDuplicateImages=true";
		cmd += " -dNOPAUSE";
		cmd += " -dBATCH";
		cmd += " '%s'".printf(escape_single_quote(file_path));

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace && file_exists(outfile)){
			file_delete(file_path) && file_move(outfile, file_path);
		}

		return (std_err.strip().length == 0);
	}

	public bool optimize(string file_path, string target, bool inplace){

		if (!file_exists(file_path)){ return false; }

		if (!silent){
			log_msg("%s:  %s".printf(_("Input"), file_path));
			log_msg("%s: %s".printf(_("Target"), target));
		}
		
		string outfile = "%s_optimized_%s.pdf".printf(file_get_title(file_path), target.down());
		outfile = path_combine(file_parent(file_path), outfile);
		
		string cmd = "gs";
		cmd += " -sOutputFile='%s'".printf(escape_single_quote(outfile));
		cmd += " -sDEVICE=pdfwrite";
		cmd += " -dCompatibilityLevel=1.4";
		cmd += " -dDetectDuplicateImages=true";
		cmd += " -dCompressFonts=true";
		cmd += " -dPDFSETTINGS=/%s".printf(target.down());
		cmd += " -dNOPAUSE";
		cmd += " -dBATCH";
		cmd += " '%s'".printf(escape_single_quote(file_path));

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace && file_exists(outfile)){
			file_delete(file_path) && file_move(outfile, file_path);
		}

		return (std_err.strip().length == 0);
	}

	public bool rotate(string file_path, string direction, bool inplace){

		if (!file_exists(file_path)){ return false; }

		if (!silent){
			log_msg("%s:  %s".printf(_("Input"), file_path));
			log_msg("%s: %s".printf(_("Mode"), direction));
		}
		
		string cmd = "pdftk";

		cmd += " '%s'".printf(escape_single_quote(file_path));

		string orientation = "";
		
		switch(direction){
		case "right":
			orientation = "east";
			break;
		case "flip":
			orientation = "south";
			break;
		case "left":
			orientation = "west";
			break;
		}

		if (orientation.length > 0){
			cmd += " cat 1-end%s".printf(orientation);
		}
		
		string title = file_get_title(file_path);
		string outfile = "%s_rotated_%s.pdf".printf(title, direction);
		outfile = path_combine(file_parent(file_path), outfile);

		cmd += " output '%s'".printf(escape_single_quote(outfile));

		if (!silent){
			log_msg("%s: %s".printf(_("Output"), outfile));
		}
		
		log_debug(cmd);

		string std_out, std_err;
		exec_sync(cmd, out std_out, out std_err);

		if (std_err.length > 0){
			log_error(std_err + "\n");
		}
		else if (inplace && file_exists(outfile)){
			file_delete(file_path) && file_move(outfile, file_path);
		}

		return (std_err.strip().length == 0);
	}

}
