# Python 3 script
import csv

sequence_length = 40    # Aantal woorden in een zin / per regel.
window_size = 2         # Overlap per regel (aantal woorden van vorige regel die vooraan nieuwe regel worden geplakt)


with open('D:\logs\Allevents-sorted.csv', 'r') as csvfile, open('D:\logs\events.csv', 'w', encoding='UTF8', newline='') as outfile:
    csvreader = csv.reader(csvfile)
    csvwriter = csv.writer(outfile, delimiter =' ', quoting=csv.QUOTE_NONE)
    regel = []
    vorigeregel = []
   	
    #reading first row of field Names
    fields = csvreader.__next__() # Doen we verder niks mee

    n = 1
	#reading rows
    for row in csvreader:
        regel.append(row[2]+row[3]+row[4].replace(' ', '-'))
        i = n % sequence_length
        if n == sequence_length:
            csvwriter.writerow(regel)
            vorigeregel = regel
            regel = []
        elif i == 0: 
            for j in range(0,window_size,1):
                regel.insert(0, vorigeregel[sequence_length - j - 1])
                regel.pop(sequence_length)
            csvwriter.writerow(regel)
            vorigeregel = regel
            regel = []

        n = n + 1
    
    print("Klaar...")
    outfile.close()
