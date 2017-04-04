# Copyright 2016, Google, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import json
import os
from google.cloud import language

# Instantiates a plain text document.
parser = argparse.ArgumentParser(
    description=__doc__,
    formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument(
    'text',
    help='The text you\'d like to analyze in JSON format. {"text" : "text content"}')
parser.add_argument(
    '--creds',
    help='The path to your Google Cloud API JSON key (optional)',
    required=False)
args = parser.parse_args()

# Accept creds file path via command line if not defined in ENV vars
if not 'GOOGLE_APPLICATION_CREDENTIALS' in os.environ:
	os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = args.creds

data = json.loads(args.text)
text = data['text']

"""Run a sentiment analysis request on text within a passed filename."""
language_client = language.Client()

document = language_client.document_from_text(text)
# Fetch sentiment
sentiment = document.analyze_sentiment().sentiment

# Fetch entities
entity_response = document.analyze_entities()
entities = []
for entity in entity_response.entities:
	entities.append(entity.name)

# Return JSON object to STDOUT
print(json.dumps({'sentiment' : {'score' : sentiment.score, 'magnitude' : sentiment.magnitude}, 'entities' : entities}))