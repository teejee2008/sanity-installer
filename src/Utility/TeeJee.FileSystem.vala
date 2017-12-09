
/*
 * TeeJee.FileSystem.vala
 *
 * Copyright 2016 Tony George <teejeetech@gmail.com>
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
 
namespace TeeJee.FileSystem{

	/* Convenience functions for handling files and directories */

	using TeeJee.Logging;
	using TeeJee.ProcessHelper;
	using TeeJee.Misc;

	public const int64 KB = 1000;
	public const int64 MB = 1000 * KB;
	public const int64 GB = 1000 * MB;
	public const int64 TB = 1000 * GB;
	public const int64 KiB = 1024;
	public const int64 MiB = 1024 * KiB;
	public const int64 GiB = 1024 * MiB;
	public const int64 TiB = 1024 * GiB;
	
	// path helpers -----------------------------------------------
	
	public string file_parent(string file_path){
		return File.new_for_path(file_path).get_parent().get_path();
	}

	public string file_basename(string file_path){
		return File.new_for_path(file_path).get_basename();
	}

	public string file_get_title(string file_path){
		
		string file_name = File.new_for_path(file_path).get_basename();

		int end = file_name.length - file_get_extension(file_path).length;
		return file_name[0:end];
	}

	public string file_get_extension(string file_path){
		
		string file_name = File.new_for_path(file_path).get_basename();

		string[] parts = file_name.split(".");

		if (parts.length == 1){
			// no extension
			return "";
		}
		
		if (parts.length > 2){
			
			string ext1 = parts[parts.length-2];
			string ext2 = parts[parts.length-1];
			
			if ((ext1.length <= 4) && (ext2.length <= 4) && (ext1 == "tar")){
				// 2-part extension
				return ".%s.%s".printf(parts[parts.length-2], parts[parts.length-1]);
			}
		}
		
		if (parts.length > 1){
			return ".%s".printf(parts[parts.length - 1]);
		}

		return "";
	}
	
	public string path_combine(string path1, string path2){
		return GLib.Path.build_path("/", path1, path2);
	}
	
	// file helpers -----------------------------------------------

	public bool file_exists (string file_path){
		/* Check if file exists */
		return (FileUtils.test(file_path, GLib.FileTest.EXISTS)
			&& !FileUtils.test(file_path, GLib.FileTest.IS_DIR));
	}

	public bool file_delete(string file_path){

		/* Check and delete file */

		try {
			var file = File.new_for_path (file_path);
			if (file.query_exists ()) {
				file.delete ();
			}
			return true;
		}
		catch (Error e) {
	        log_error (e.message);
	        log_error(_("Failed to delete file") + ": %s".printf(file_path));
	        return false;
	    }
	}

	public string? file_read (string file_path){

		/* Reads text from file */

		string txt;
		size_t size;

		try{
			GLib.FileUtils.get_contents (file_path, out txt, out size);
			return txt;
		}
		catch (Error e){
	        log_error (e.message);
	        log_error(_("Failed to read file") + ": %s".printf(file_path));
	    }

	    return null;
	}

	public bool file_write (string file_path, string contents, bool overwrite_in_place = false){

		/* Write text to file */

		try{

			dir_create(file_parent(file_path));
			
			var file = File.new_for_path (file_path);

			if (file.query_exists() && overwrite_in_place){

				var iostream = file.open_readwrite();
				//int64 fsize = iostream.query_info("%s".printf(FileAttribute.STANDARD_SIZE)).get_size();
				//iostream.seek (0, GLib.SeekType.END);
				iostream.truncate_fn(0);
				//iostream.seek (0, GLib.SeekType.SET);
				var ostream = iostream.output_stream;
				var data_stream = new DataOutputStream(ostream);
				data_stream.put_string(contents);
				data_stream.close();
			}
			else{

				if (file.query_exists()) {
					file.delete();
				}
	
				var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
				var data_stream = new DataOutputStream (file_stream);
				data_stream.put_string (contents);
				data_stream.close();
			}
			
			return true;
		}
		catch (Error e) {
			log_error(e.message);
			return false;
		}
	}

	public bool file_copy (string src_file, string dest_file){
		try{
			var file_src = File.new_for_path (src_file);
			if (file_src.query_exists()) {
				var file_dest = File.new_for_path (dest_file);
				file_src.copy(file_dest,FileCopyFlags.OVERWRITE,null,null);
				log_msg("copy: '%s' -> '%s'".printf(src_file, dest_file));
				return true;
			}
		}
		catch(Error e){
	        log_error (e.message);
	        log_error(_("Failed to copy file") + ": '%s', '%s'".printf(src_file, dest_file));
		}

		return false;
	}

	public bool file_move (string src_file, string dest_file){
		try{
			var file_src = File.new_for_path (src_file);
			if (file_src.query_exists()) {
				var file_dest = File.new_for_path (dest_file);
				file_src.move(file_dest,FileCopyFlags.OVERWRITE,null,null);
				return true;
			}
			else{
				log_error(_("File not found") + ": '%s'".printf(src_file));
				return false;
			}
		}
		catch(Error e){
	        log_error (e.message);
	        log_error(_("Failed to move file") + ": '%s', '%s'".printf(src_file, dest_file));
	        return false;
		}
	}

	// directory helpers --------------------------------------------
	
	public bool dir_exists (string dir_path){
		/* Check if directory exists */
		return ( FileUtils.test(dir_path, GLib.FileTest.EXISTS) && FileUtils.test(dir_path, GLib.FileTest.IS_DIR));
	}
	
	public bool dir_create (string dir_path, bool show_message = false){

		/* Creates a directory along with parents */

		try{
			var dir = File.parse_name (dir_path);
			if (dir.query_exists () == false) {
				dir.make_directory_with_parents (null);
				if (show_message){
					log_msg(_("Created directory") + ": %s".printf(dir_path));
				}
			}
			return true;
		}
		catch (Error e) {
			log_error (e.message);
			log_error(_("Failed to create dir") + ": %s".printf(dir_path));
			return false;
		}
	}

	public bool dir_delete (string dir_path, bool show_message = false){
		
		/* Recursively deletes directory along with contents */
		
		if (!dir_exists(dir_path)){
			return true;
		}
		
		string cmd = "rm -rf '%s'".printf(escape_single_quote(dir_path));
		int status = exec_sync(cmd, null, null);
		if (show_message){
			log_msg(_("Deleted directory") + ": %s".printf(dir_path));
		}
		return (status == 0);
	}

	public bool chown(string dir_path, string user, string group = user){
		string cmd = "chown %s:%s -R '%s'".printf(user, group, escape_single_quote(dir_path));
		int status = exec_sync(cmd, null, null);
		return (status == 0);
	}
	
	public string escape_single_quote(string file_path){
		return file_path.replace("'","'\\''");
	}

	// dep: chmod
	public int chmod (string file, string permission){

		/* Change file permissions */
		string cmd = "chmod %s '%s'".printf(permission, escape_single_quote(file));
		return exec_sync (cmd, null, null);
	}
}
