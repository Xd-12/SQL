# Assignment 1

import pandas as pd
import numpy as np

path1 = '/Users/xiaodongnie/Desktop/ICC/PYTHON/Python_HW/people/people_1.txt'
path2 = '/Users/xiaodongnie/Desktop/ICC/PYTHON/Python_HW/people/people_2.txt'

#  Read two text files
df1 = pd.read_csv(path1,sep='\t')
df2 = pd.read_csv(path2,sep='\t')

# Merge two dataframes
frames = [df1, df2]
df3 = pd.concat(frames)

# Unified format
df3['FirstName'] = df3.FirstName.str.upper()
df3['FirstName'] = df3.FirstName.str.strip()
df3['LastName'] = df3.LastName.str.upper()
df3['LastName'] = df3.LastName.str.strip()
df3['Email'] = df3.Email.str.upper()
df3['Email'] = df3.Email.str.strip()
df3['Phone'] = df3['Phone'].astype(str).apply(lambda x: np.where( len(x)<=10, x[:3]+'-'+x[3:6]+'-'+x[6:10],x))
df3['Address'] = df3.Address.str.lstrip('#')
df3['Address'] = df3.Address.str.lstrip('No.')


# Drop duplicates
df4 = df3.drop_duplicates()

# Create a csv file
df4.to_csv('/Users/xiaodongnie/Desktop/ICC/PYTHON/Python_HW/people/people.csv')

# Assignment 2
import json

# Read json file
json_path = '/Users/xiaodongnie/Desktop/ICC/PYTHON/Python_HW/movie.json'
with open(json_path, 'r') as f:
    movie_info = json.load(f)

# Define how many content of lines should be add into each small json file.
total_num = len(movie_info['movie'])//8

# create 8 samll json files
for i in range(8):
    json.dump(movie_info['movie'][i*total_num:(i+1)*total_num],open('/Users/xiaodongnie/Desktop/ICC/PYTHON/Python_HW/'+ str(i) + '.json','w'),indent = True)







