import json
import os

def read_config():
    main_base= os.path.dirname(__file__)
    config_fname=os.path.join(main_base,'..','..','config.json')
    with open(config_fname) as json_file:
        data=json.load(json_file)
    return data