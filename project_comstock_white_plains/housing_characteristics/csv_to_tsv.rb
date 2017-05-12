
# First, add this macro to the spreadsheet to export all files as CSV
=begin
Sub exportcsv()
Dim ws As Worksheet
Dim path As String

path = ActiveWorkbook.path & "\" & Left(ActiveWorkbook.Name, InStr(ActiveWorkbook.Name, ".") - 1)
For Each ws In Worksheets
    ws.Activate
    ActiveWorkbook.SaveAs Filename:=path & "_" & ws.Name & ".csv", FileFormat:=xlCSV, CreateBackup:=False
Next
End Sub
=end

# Then, run this ruby script
prefix = '2017_04_27_TSVs_NY_'
Dir.glob("*.csv").each do |csv|

  filename = csv.gsub(prefix,'').gsub('.csv','')
  
  puts "found #{filename}"

  csv = File.read(csv)

  tsv = csv.gsub(",","\t")

  File.open("#{Dir.pwd}/#{filename}.tsv", 'w') do |file|
    file.puts tsv
  end
  
end
