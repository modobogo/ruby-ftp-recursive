#!/usr/bin/env ruby
#encoding: UTF-8

# +FLOW: 引入必要的函式庫
require 'net/ftp'

class Net::FTP
  # 儲存透過 scan 方法所取得檔案名稱資料
  @@scan_files = []

  # 輔助方法：取得 directory_name 下的所有檔案與資料夾資料
  def scan ( directory_name = ['/'] )
    if directory_name.is_a? Fixnum or directory_name.is_a? Bignum then
      directory_name = [ directory_name.to_s ] 
    elsif directory_name.is_a? String
      directory_name = [ directory_name ] if directory_name.is_a? String
    elsif directory_name.is_a? Array
      # nothing..
    else
      directory_name = ['/']
    end

    @@scan_files.clear
    
    directory_name.each do |directory_name|
      self._scan(directory_name)
    end

    @@scan_files
  end

  # 輔助方法：從 FTP LIST 指令回傳的資料，取得較為正確檔案的名稱
  def get_name_by_list ( file_info )
    # 透過時間日期作為切割資料的依據
    file_info = file_info.split(/[A-Z]{3}\s{1,2}\d{1,2}\s{2}\d{4}\s(.+)$|[A-Z]{3}\s{1,2}\d{1,2}\s{1}\d{2}:\d{2}\s(.+)$/i)

    # 若切出來的資料有兩項，則表示陣列內最後一個即為檔案名稱
    return file_info.last if 2 == file_info.length

    # 若切割出來資料不是兩個，則以空白間隔做切割，取陣列內最後一個作為檔案名稱
    # 流程注意：在這個狀況下，檔案或資料夾名稱含有空白字元，切割出來的名稱會是錯誤的
    file_info.split.last
  end

  protected
  # 輔助方法：scan 方法的核心程式，透過遞迴的方式取得檔案列表
  def _scan ( directory_name )
    begin
      self.chdir(directory_name)

      pwd = self.pwd
      @@scan_files << pwd
      files_list = self.list

      files_list.each do |file_info|
        if file_info[0] =~ /d/i then
          next_directory_name = get_name_by_list(file_info)
          self._scan(next_directory_name)  if '.' != next_directory_name && '..' != next_directory_name
        else
          next_file_name = get_name_by_list(file_info)
          @@scan_files << ( '/' == pwd ? "/#{next_file_name}" : "#{pwd}/#{next_file_name}" )
        end
      end

      self.chdir('..')
    rescue Exception => reason
      # nothing..
      STDOUT.puts reason.message
    end
  end
end

# 範例
# ftp = Net::FTP.new('FTP空間位置ADDRESS')
# ftp.login('帳號USERNAME', '密碼PASSWORD')
# puts ftp.scan
# ftp.close