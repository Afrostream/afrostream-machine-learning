from __future__ import print_function
from keras.models import Sequential
from keras.layers import Dense, Activation
from keras.layers import LSTM
from keras.optimizers import RMSprop
from keras.utils.data_utils import get_file
import numpy as np
import random
import sys

# on defini arbitrairement
maxlen = 32

# on relit les caractère du fichier canceled
text = open('canceled.txt').read().lower()
print('corpus length:', len(text))
chars = sorted(list(set(text)))
print('total chars:', len(chars))
char_indices = dict((c, i) for i, c in enumerate(chars))
indices_char = dict((i, c) for i, c in enumerate(chars))

# on cree le réseau
model = Sequential()
model.add(LSTM(128, input_shape=(maxlen, len(chars))))
model.add(Dense(len(chars)))
model.add(Activation('softmax'))

optimizer = RMSprop(lr=0.001)

# chargement des poids
model.load_weights("weights.h5")

# on charge les "actives"
text = open('active.txt').read().lower()
sentences = text.split()

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def sample(preds, temperature=1.0):
    # helper function to sample an index from a probability array
    preds = np.asarray(preds).astype('float64')
    preds = np.log(preds) / temperature
    exp_preds = np.exp(preds)
    preds = exp_preds / np.sum(exp_preds)
    probas = np.random.multinomial(1, preds, 1)
    return np.argmax(probas)

for l, sentence in enumerate(sentences):
    # la sentence a la forme userId:(...)
    # on strip le userID
    userId, sentence = sentence.split(':')

    sys.stdout.write("line %d: %s %s" % (l, userId, bcolors.OKBLUE+sentence))
    # on prend les 64 derniers chars
    sentence = sentence[-maxlen:]
    # on pop, le debut pour y ajouter un "b" de begin
    sentence = 'b' + sentence[1:]
    # on pad a gauche avec des "."
    sentence.rjust(maxlen, '.')

    #
    generated = '' + sentence
    # on essaye de prédire les 16 chars qui vont suivre ... :)

    sys.stdout.write(bcolors.OKGREEN)
    for i in range(128):
        x = np.zeros((1, maxlen, len(chars)))
        for t, char in enumerate(sentence):
            x[0, t, char_indices[char]] = 1.

        preds = model.predict(x, verbose=0)[0]
        next_index = sample(preds)
        next_char = indices_char[next_index]

        generated += next_char
        sentence = sentence[1:] + next_char

        # printing char
        sys.stdout.write(next_char)

        if next_char == '.' or next_char == 'x':
            if i > 10:
                sys.stdout.write(bcolors.WARNING+' [OK]')
            else:
                sys.stdout.write(bcolors.FAIL+' [FUTUR CANCELED]')
            break
    sys.stdout.write(bcolors.ENDC+"\n")
    sys.stdout.flush()
