"""Deterministic checks of the optional device CI boundary; no provider/network needed."""
import contextlib, io, json, os, runpy, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
SCRIPT=Path(__file__).with_name('browserstack.py')
class DeviceCIContractTests(unittest.TestCase):
    def execute(self, status='passed', count=1, stale=False):
        with tempfile.TemporaryDirectory() as directory:
            env={'BROWSERSTACK_USERNAME':'test-user','BROWSERSTACK_ACCESS_KEY':'test-access-key',
                'BROWSERSTACK_APP_URL':'bs://approved-app','BROWSERSTACK_TEST_SUITE_URL':'bs://approved-suite',
                'BROWSERSTACK_BUILD_SHA':'old' if stale else 'candidate','GITHUB_SHA':'candidate',
                'VEIL_DEVICE':'test-device','VEIL_DEVICE_OUTPUT':directory}
            result={'status':status,'duration':1,'private_url':'do-not-export',
                'devices':[{'sessions':[{'testcases':{'count':count,'status':{'passed':count}}}]}]}
            responses=[io.BytesIO(json.dumps(x).encode()) for x in [{'build_id':'test-build'},result]]
            stdout=io.StringIO()
            with patch.dict(os.environ,env),patch('sys.argv',[str(SCRIPT)]),patch('urllib.request.urlopen',side_effect=responses) as network,contextlib.redirect_stdout(stdout):
                if stale:
                    with self.assertRaises(AssertionError):runpy.run_path(str(SCRIPT),run_name='__main__')
                    network.assert_not_called();return
                with self.assertRaises(SystemExit) as exit_:runpy.run_path(str(SCRIPT),run_name='__main__')
                submitted=json.loads(network.call_args_list[0].args[0].data)
                self.assertEqual(submitted['only-testing'],['VeilDeviceAcceptanceTests'])
                self.assertFalse(submitted['networkLogs'])
                evidence=Path(directory,'provider-result.json').read_text()
                self.assertNotIn('do-not-export',evidence+stdout.getvalue())
                self.assertNotIn('test-access-key',evidence+stdout.getvalue())
                return exit_.exception.code
    def testApprovedBuildAndPositiveCaseCountPass(self):self.assertEqual(self.execute(),0)
    def testDoneRequiresPositiveCaseCount(self):self.assertEqual(self.execute(status='done'),0)
    def testZeroTestsIsFailureEvenWhenProviderSaysPassed(self):self.assertEqual(self.execute(count=0),1)
    def testProviderFailureRemainsFailure(self):self.assertEqual(self.execute(status='failed'),1)
    def testStaleSignedArtifactCannotRunForNewCandidate(self):self.execute(stale=True)
if __name__=='__main__':unittest.main()
