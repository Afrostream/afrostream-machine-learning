# Description

on veut prédire les désabonnements volontaires

# Utilisation d'un RNN (Recurrent Neural Network)

les séquences ont la forme suivante :

```
Séquence:
                   Etape 0   ...   Etape i   ...   Etape N   
activation abonnement o------------------------------------> désactivation abonnement
```

```
SEQUENCE =
 b = activation abonnement
 m = lecture d'un film
 s = lecture d'une serie
 eN = lecture de l'episode N
 k = skip (lecture a durée < 5min)
 x = fin d'abonnement
```

remarque: la lecture d'un épisode entraine l'insertion d'une sequence de la forme :
```
seN : l'episode a été lu après un film ou après un épisode d'une série différente
 ou
eN : l'episode a été lu après un épisode de la même série
```

exemples de séquences :

```
bse1e2e3e4e5e6e7e8e9se18e19e21fse1e2e3e4e5e6e7e8fx
bse1e2e3e4se1se5e6e7se1e2se1ke2e3ke4kse1ffse3se2
bfffffse1e5x
bse1e2e3e4e5se1se1e2e3se6e7e8e9e10e11e12se4se8kse1kse1e2kse4kse5e6se3kse7e8e9e10ke11e12fkse13e14e15e16ke17ke18e19e20e21e22e23e24se5se1e2e3se1kse4e5e6e7e8kse3kse3se1e2e3kse6e3e5e1k
```

détail :

```
bffse1e5x <=> begin + film + film + episode 1 & episode 5 d'une série + désabonnement.
```

vous trouverez des exemples de sequences dans canceled.txt & active.txt

# Implémentation, on utilise keras (LSTM)

on se base sur l'implémentation faite par https://github.com/fchollet/keras/blob/master/examples/lstm_text_generation.py

une sequence de lecture aura la for

l'idée est de padder gauche les sequences de lectures par un .

exemple d'output de npm run test :

![output](https://github.com/Afrostream/afrostream-machine-learning/raw/master/predict-cancel/output.jpg)

chaque ligne a la forme suivante :
line {numero}: {userId} {sequence active}{sequence predite}

en bleu donc les sequences actives, en vert la suite prédite par le RNN.
