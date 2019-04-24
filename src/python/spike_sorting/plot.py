import os
import matplotlib
import numpy as np
import matplotlib.pyplot as plt
from tridesclous import plot_centroids, plot_waveforms_histogram, plot_isi, median_mad


def plot_waveforms(wave_forms):
    fig = plt.figure()
    ax = fig.add_subplot(1, 1, 1)
    ax.plot(wave_forms, color='blue', alpha=0.1)
    ax.set_ylabel('MAD')
    return fig


def plot_cluster_waveforms(cc, cluster_labels, title=None):
    fig, ax = plt.subplots(ncols=1, nrows=1)
    time_range = range(cc.info['waveform_extractor_params']['n_left'],
                       cc.info['waveform_extractor_params']['n_right'])
    # centroids
    for idx, cluster_label in enumerate(cluster_labels):
        if cluster_label >= 0:
            color = cc.colors.get(cluster_label, 'k')
            ind = np.nonzero(cc.cluster_labels == cluster_label)[0][0]
            cell_label = cc.clusters['cell_label'][ind]

            max_channel = cc.clusters['max_on_channel'][ind]
            ax.plot(time_range, cc.centroids_median[ind, :, max_channel], color=color,
                    label='%d, %d' % (cluster_label, cell_label))
            ax.fill_between(time_range,
                            cc.centroids_median[ind, :, max_channel] - cc.centroids_std[ind, :, max_channel],
                            cc.centroids_median[ind, :, max_channel] + cc.centroids_std[ind, :, max_channel],
                            alpha=0.2, edgecolor=color, facecolor=color)
    ax.legend(loc='best', prop={'size': 6})
    if title is None:
        title='Amplitude in MAD (STD) ratio'
    ax.set_title(title)
    return fig

def plot_noise(cc):
    median, mad = median_mad(np.squeeze(cc.some_noise_snippet), axis=0)
    fig = plt.figure()
    ax = fig.add_subplot(3, 1, 1)
    ax.plot(np.transpose(np.squeeze(cc.some_noise_snippet)), color='blue', alpha=0.1)
    ax.set_ylim((-5, 5))
    ax = fig.add_subplot(3, 1, 2)
    ax.plot(median, color='blue')
    ax.set_ylabel('Median')
    ax.set_ylim((-5, 5))
    ax = fig.add_subplot(3, 1, 3)
    ax.plot(mad, color='blue')
    ax.set_ylim((-5, 5))
    ax.set_ylabel('MAD')
    return fig


_cluster_summary_template = """
Cluster {cluster_label}, Cell {cell_label}
Max on channel (abs): {max_on_channel_abs}
Max on channel (local to group): {max_on_channel}
Peak amplitude MAD: {max_peak_amplitude:.1f}
Peak amplitude (µV): {max_peak_amplitude_uV:.1f}
Nb spikes : {nb_spike}

"""

def plot_cluster_summary(dataio, catalogue, chan_grp, cluster_label):

    clusters = catalogue['clusters']

    channel_abs = dataio.channel_groups[chan_grp]['channels']

    show_channels = False

    ind = np.nonzero(clusters['cluster_label'] == cluster_label)[0][0]

    cell_label=clusters['cell_label'][ind]
    cluster = clusters[ind]

    max_on_channel = cluster['max_on_channel']
    if max_on_channel >= 0:
        max_on_channel_abs = channel_abs[max_on_channel]
    else:
        max_on_channel = None
        max_on_channel_abs = None

    max_peak_amplitude = cluster['max_peak_amplitude']
    max_peak_amplitude_uV = np.nan
    if dataio.datasource.bit_to_microVolt is not None and max_on_channel is not None:
        max_peak_amplitude_uV = max_peak_amplitude * catalogue['signals_mads'][
            max_on_channel] * dataio.datasource.bit_to_microVolt

    nb_spike = 0
    for seg_num in range(dataio.nb_segment):
        all_spikes = dataio.get_spikes(seg_num=seg_num, chan_grp=chan_grp)
        nb_spike += np.sum(all_spikes['cluster_label'] == cluster_label)

    fig, axs = plt.subplots(ncols=2, nrows=2)
    axs[0, 0].remove()
    # centroids
    ax = axs[0, 1]
    plot_centroids(catalogue, dataio=dataio, labels=[cluster_label, ], ax=ax, show_channels=show_channels,
                   neighborhood_radius=None)
    ax.set_title('cluster {}, cell {}'.format(cluster_label, cell_label))

    # waveform density
    ax = axs[1, 1]
    if dataio.datasource.bit_to_microVolt is None:
        units = 'MAD'
        title = 'Amplitude in MAD (STD) ratio'
    else:
        units = 'uV'
        title = 'Amplitude μV'

    plot_channels_hist = [max_on_channel]

    if nb_spike>0:
        plot_waveforms_histogram(catalogue, dataio=dataio, label=cluster_label, ax=ax, channels=plot_channels_hist,
                                 units=units)
        ax.set_title(title)

    # ISI
    ax = axs[1, 0]
    plot_isi(dataio, catalogue=catalogue, chan_grp=chan_grp, label=cluster_label, ax=ax, bin_min=0, bin_max=100,
             bin_size=1.)
    ax.set_title('ISI (ms)')

    d = dict(chan_grp=chan_grp,
             cluster_label=cluster_label,
             cell_label=cell_label,
             max_on_channel=max_on_channel,
             max_on_channel_abs=max_on_channel_abs,
             max_peak_amplitude=max_peak_amplitude,
             max_peak_amplitude_uV=max_peak_amplitude_uV,
             nb_spike=nb_spike,

             )

    text = _cluster_summary_template.format(**d)

    # ~ print(text)

    ax.figure.text(.05, .75, text, va='center')  # , ha='center')

    return fig


def plot_clusters_summary(dataio, catalogueconstructor, chan_grp, bin_min = 0, bin_max = 100, bin_size = 1.):

    fig, axs = plt.subplots(ncols=2, nrows=2)

    catalogue = dataio.load_catalogue(chan_grp=chan_grp)
    time_range=range(catalogueconstructor.info['waveform_extractor_params']['n_left'], catalogueconstructor.info['waveform_extractor_params']['n_right'])
    sr = dataio.sample_rate

    clusters = catalogue['clusters']

    cluster_labels = clusters['cluster_label']
    cell_labels = clusters['cell_label']

    axs[0, 0].remove()
    # centroids
    ax = axs[0, 1]

    for cluster_label, cell_label in zip(cluster_labels,cell_labels):
        color = catalogueconstructor.colors.get(cluster_label, 'k')
        ind = np.nonzero(catalogueconstructor.cluster_labels == cluster_label)[0][0]
        max_channel = catalogueconstructor.clusters['max_on_channel'][ind]
        ax.plot(time_range, catalogueconstructor.centroids_median[ind, :, max_channel], color=color, label='%d, %d' % (cluster_label, cell_label))
        ax.fill_between(time_range, catalogueconstructor.centroids_median[ind, :, max_channel] - catalogueconstructor.centroids_std[ind, :, max_channel],
                        catalogueconstructor.centroids_median[ind, :, max_channel] + catalogueconstructor.centroids_std[ind, :, max_channel],
                        alpha=0.2, edgecolor=color, facecolor=color)
    ax.legend(loc='best', prop={'size': 6})
    ax.set_title('Amplitude in MAD (STD) ratio')

    ax = axs[1, 0]
    if len(cluster_labels):
        catalogueconstructor.compute_cluster_similarity()
        im, cbar = heatmap(catalogueconstructor.cluster_similarity, ['%d' % x for x in range(len(cluster_labels))],
                           ['%d' % x for x in range(len(cluster_labels))], ax=ax, cbarlabel='cluster similarity')
        texts = annotate_heatmap(im, valfmt='{x:.2f}', textcolors=['white','black'])

    ax = axs[1, 1]
    bins = np.arange(bin_min, bin_max, bin_size)
    for cluster_label, cell_label in zip(cluster_labels, cell_labels):
        count = None
        color = catalogueconstructor.colors.get(cluster_label, 'k')
        for seg_num in range(dataio.nb_segment):
            spikes = dataio.get_spikes(seg_num=seg_num, chan_grp=chan_grp, )
            spikes = spikes[spikes['cluster_label'] == cluster_label]
            spike_indexes = spikes['index']

            isi = np.diff(spike_indexes) / (sr / 1000.)

            count_, bins = np.histogram(isi, bins=bins)
            if count is None:
                count = count_
            else:
                count += count_

        ax.plot(bins[:-1], count, color=color, label='%d, %d' % (cluster_label, cell_label))
    ax.legend(loc='best', prop={'size': 6})
    ax.set_title('ISI (ms)')

    fig.tight_layout()

    return fig


def heatmap(data, row_labels, col_labels, ax=None,
            cbar_kw={}, cbarlabel="", **kwargs):
    """
    Create a heatmap from a numpy array and two lists of labels.

    Arguments:
        data       : A 2D numpy array of shape (N,M)
        row_labels : A list or array of length N with the labels
                     for the rows
        col_labels : A list or array of length M with the labels
                     for the columns
    Optional arguments:
        ax         : A matplotlib.axes.Axes instance to which the heatmap
                     is plotted. If not provided, use current axes or
                     create a new one.
        cbar_kw    : A dictionary with arguments to
                     :meth:`matplotlib.Figure.colorbar`.
        cbarlabel  : The label for the colorbar
    All other arguments are directly passed on to the imshow call.
    """

    if not ax:
        ax = plt.gca()

    # Plot the heatmap
    im = ax.imshow(data, **kwargs)

    # Create colorbar
    cbar = ax.figure.colorbar(im, ax=ax, **cbar_kw)
    cbar.ax.set_ylabel(cbarlabel, rotation=-90, va="bottom")

    # We want to show all ticks...
    ax.set_xticks(np.arange(data.shape[1]))
    ax.set_yticks(np.arange(data.shape[0]))
    # ... and label them with the respective list entries.
    ax.set_xticklabels(col_labels)
    ax.set_yticklabels(row_labels)

    # Let the horizontal axes labeling appear on top.
    ax.tick_params(top=True, bottom=False,
                   labeltop=True, labelbottom=False)

    # Rotate the tick labels and set their alignment.
    plt.setp(ax.get_xticklabels(), rotation=-30, ha="right",
             rotation_mode="anchor")

    # Turn spines off and create white grid.
    for edge, spine in ax.spines.items():
        spine.set_visible(False)

    ax.set_xticks(np.arange(data.shape[1]+1)-.5, minor=True)
    ax.set_yticks(np.arange(data.shape[0]+1)-.5, minor=True)
    ax.grid(which="minor", color="w", linestyle='-', linewidth=3)
    ax.tick_params(which="minor", bottom=False, left=False)

    return im, cbar


def annotate_heatmap(im, data=None, valfmt="{x:.2f}",
                     textcolors=["black", "white"],
                     threshold=None, **textkw):
    """
    A function to annotate a heatmap.

    Arguments:
        im         : The AxesImage to be labeled.
    Optional arguments:
        data       : Data used to annotate. If None, the image's data is used.
        valfmt     : The format of the annotations inside the heatmap.
                     This should either use the string format method, e.g.
                     "$ {x:.2f}", or be a :class:`matplotlib.ticker.Formatter`.
        textcolors : A list or array of two color specifications. The first is
                     used for values below a threshold, the second for those
                     above.
        threshold  : Value in data units according to which the colors from
                     textcolors are applied. If None (the default) uses the
                     middle of the colormap as separation.

    Further arguments are passed on to the created text labels.
    """

    if not isinstance(data, (list, np.ndarray)):
        data = im.get_array()

    # Normalize the threshold to the images color range.
    if threshold is not None:
        threshold = im.norm(threshold)
    else:
        threshold = im.norm(data.max())/2.

    # Set default alignment to center, but allow it to be
    # overwritten by textkw.
    kw = dict(horizontalalignment="center",
              verticalalignment="center")
    kw.update(textkw)

    # Get the formatter in case a string is supplied
    if isinstance(valfmt, str):
        valfmt = matplotlib.ticker.StrMethodFormatter(valfmt)

    # Loop over the data and create a `Text` for each "pixel".
    # Change the text's color depending on the data.
    texts = []
    for i in range(data.shape[0]):
        for j in range(data.shape[1]):
            kw.update(color=textcolors[im.norm(data[i, j]) > threshold])
            text = im.axes.text(j, i, valfmt(data[i, j], None), **kw)
            texts.append(text)

    return texts