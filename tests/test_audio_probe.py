import sys
from pathlib import Path
import unittest
from unittest.mock import patch
import json
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from audio_probe import RATE, FREQUENCY, tone_rms, validate_gain_sweep, streams


class AudioMeasurementTests(unittest.TestCase):
    def test_routes_game_application_but_not_browser_title(self):
        rows = [
            {'index': 1, 'properties': {'application.name': 'Firefox', 'media.name': 'Abiotic Factor Mods'}},
            {'index': 2, 'properties': {'application.name': 'Abiotic Factor', 'application.process.binary': 'wine64-preloader'}},
        ]
        with patch('audio_probe.pactl', return_value=json.dumps(rows)):
            self.assertEqual([r['index'] for r in streams('sink-inputs', r'Abiotic\s*Factor')], [2])

    def test_detects_amplitude_change_in_recorded_samples(self):
        time = np.arange(RATE * 2) / RATE
        quiet = np.repeat((0.01 * np.sin(2*np.pi*FREQUENCY*time))[:, None], 2, axis=1).ravel()
        self.assertAlmostEqual(tone_rms(quiet * 2) / tone_rms(quiet), 2, places=5)

    def test_rejects_zero_only_control_that_leaves_positive_gains_unchanged(self):
        samples = [{'gain': gain, 'tone_rms': 0 if gain == 0 else 0.01}
                   for gain in (0, 0.1, 0.5, 1, 2, 4)]
        with self.assertRaisesRegex(RuntimeError, 'Gain response'):
            validate_gain_sweep(samples)

    def test_accepts_linear_measured_response(self):
        samples = [{'gain': gain, 'tone_rms': gain * 0.01}
                   for gain in (0, 0.1, 0.5, 1, 2, 4)]
        validate_gain_sweep(samples)

    def test_rejects_background_noise_as_a_test_signal(self):
        with self.assertRaisesRegex(RuntimeError, 'No test tone'):
            validate_gain_sweep([{'gain': 0, 'tone_rms': 0.001}, {'gain': 1, 'tone_rms': 0.0011}])

    def test_rejects_absent_test_signal(self):
        with self.assertRaisesRegex(RuntimeError, 'No test tone'):
            validate_gain_sweep([{'gain': 1, 'tone_rms': 0}])


if __name__ == '__main__':
    unittest.main()
