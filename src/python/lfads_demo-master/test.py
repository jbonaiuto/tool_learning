import torch
import torchvision
np = torch._np
import matplotlib.pyplot as plt

import os
import yaml
import pandas as pd
from lfads import LFADS_Net
from utils import read_data, load_parameters, save_parameters
from config import read_config


def bin_spikes(self, n_bins):
    """
    Bins spikes into dense array of spike counts. Any spikes occuring
    before self.tmin or after self.tmax are ignored.
    Parameters
    ----------
    n_bins : int
        Number of timebins per trial.
    Returns
    -------
    binned : ndarray
        Binned spike counts (n_trials x n_bins x n_neurons).
    Raises
    ------
    ValueError: If n_bins is not a positive integer.
    """
    if n_bins <= 0 or not np.issubdtype(type(n_bins), np.integer):
        raise ValueError("Expected 'n_bins' to be a positive integer, but "
                         "saw {}".format(n_bins))

    # Compute bin for each spike. It is important not to cast to integer
    # indices because fractional_spiketimes contains negative entries
    # and negative decimals round upwards. Thus, we keep bin_ids as floats
    # and handle the negative indices in _fast_bin.
    _eps = 1e-9
    bin_ids = _eps + (self.fractional_spiketimes * (n_bins - 2 * _eps))

    # Allocate space for result.
    shape = (self.n_trials, n_bins, self.n_neurons)
    binned = np.zeros(shape, dtype=float)

    # Add up all spike counts and return result.
    _fast_bin(binned, self.trials, bin_ids, self.neurons)
    return binned

def _fast_bin(counts, trials, bins, neurons):
    """
    Given coordinates of spikes, compile binned spike counts. Throw away
    spikes that are outside of tmin and tmax.
    """
    for i, j, k in zip(trials, bins, neurons):
        if (j < 0) or (int(j) >= counts.shape[1]):
            pass  # spike is less than TMIN, or greater than TMAX.
        else:
            counts[i, int(j), k] += 1

if __name__=='__main__':
    # Select device to train LFADS on
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print('Using device: %s' % device)

    if os.path.exists('./synth_data/chaotic_rnn_300'):
        data_dict = read_data('./synth_data/chaotic_rnn_300')
    else:
        if not os.path.isdir('./synth_data'):
            os.mkdir('./synth_data/')

        from synth_data_chaotic_rnn import generate_data

        data_dict = generate_data(T=1, dt_rnn=0.01, dt_cal=0.01,
                                  Ninits=400, Ntrial=10, Ncells=50, trainp=0.8,
                                  tau=0.025, gamma=1.5, maxRate=30, B=20,
                                  seed=300, save=True)
        # data_dict - dictionary with
    #     train_spikes = 800 (trials) x 100  (time) x 50 (cells)
    #     valid_spikes = 3200 x 100 x 50

    dates = ['01.03.19', '04.03.19', '05.03.19', '07.03.19', '08.03.19', '11.03.19',
             '12.03.19', '13.03.19', '14.03.19', '15.03.19', '18.03.19', '19.03.19', '20.03.19', '21.03.19', '22.03.19',
             '25.03.19', '26.03.19']
    conditions = ['motor_grasp_left', 'motor_grasp_center', 'motor_grasp_right']
    array_name='F1'

    cfg = read_config()
    trials = []
    times = []
    neurons = []
    for ch_idx in range(cfg['n_channels_per_array']):
        overall_trial_idx = 0
        for date in dates:
            date_dir = os.path.join(cfg['preprocessed_data_dir'], 'betta', date)
            info = pd.read_csv(os.path.join(date_dir, 'trial_info.csv'))
            spikes = pd.read_csv(os.path.join(date_dir, 'spikes', '%s_%s_spikes.csv' % (array_name, ch_idx)))

            for condition in conditions:
                trial_idxs = np.where((info.condition == condition) & (info.status == 'good'))[0]
                for trial_idx in trial_idxs:
                    spike_times = spikes.time[spikes.trial == info.overall_trial[trial_idx]]
                    for spike_time in spike_times:
                        trials.append(overall_trial_idx)
                        times.append(spike_time * 1000)
                        neurons.append(ch_idx)
                    overall_trial_idx = overall_trial_idx + 1


    train_data = torch.Tensor(data_dict['train_spikes']).to(device)
    valid_data = torch.Tensor(data_dict['valid_spikes']).to(device)

    train_truth = torch.Tensor(data_dict['train_rates']).to(device)
    valid_truth = torch.tensor(data_dict['valid_rates']).to(device)

    train_ds = torch.utils.data.TensorDataset(train_data)
    valid_ds = torch.utils.data.TensorDataset(valid_data)

    num_trials, num_steps, num_cells = train_data.shape
    print(train_data.shape)

    # Show example trial
    plt.figure(figsize=(12, 12))
    plt.imshow(data_dict['train_spikes'][0].T, cmap=plt.cm.Greys)
    plt.xticks(np.linspace(0, 100, 6), ['%.1f' % i for i in np.linspace(0, 1, 6)])
    plt.xlabel('Time (s)')
    plt.ylabel('Cell #')
    plt.colorbar(orientation='horizontal', label='# Spikes in 0.01 s time bin')
    plt.title('Example trial')
    plt.show()

    # Show example ground truth firing rates
    plt.figure(figsize=(12, 12))
    plt.imshow(data_dict['train_rates'][0].T, cmap=plt.cm.plasma)
    plt.xticks(np.linspace(0, 100, 6), ['%.1f' % i for i in np.linspace(0, 1, 6)])
    plt.xlabel('Time (s)')
    plt.ylabel('Cell #')
    plt.colorbar(orientation='horizontal', label='Firing Rate (Hz)')
    plt.title('Example trial')
    plt.show()

    # Load model hyperparameters
    hyperparams = load_parameters('./parameters_demo.yaml')
    save_parameters(hyperparams)

    # Instantiate model
    model = LFADS_Net(inputs_dim=num_cells, T=num_steps, dt=0.01, device=device,
                      model_hyperparams=hyperparams).to(device)

    # Fit model
    #model.fit(train_ds, valid_ds, max_epochs=200, batch_size=200, use_tensorboard=True,
    #          train_truth=train_truth, valid_truth=valid_truth)
    # Load checkpoint with lowest validation error
    model.load_checkpoint('best')

    # Plot results summary
    model.plot_summary(data=valid_data, truth=valid_truth)
    plt.show()


    pass