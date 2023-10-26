import io
import sys
import unittest
import modify_git_log


class TestModifyGitLog(unittest.TestCase):
    def test_upper(self):
        input = """
0	0	src/{modules => views}/file.py
0	2	src/modules/file.py
2	5	src/setup.py
10	12	src/{views => modules}/file.py
0	2	src/views/file.py
        """

        expected = """
0	0	src/views/file.py
0	2	src/views/file.py
2	5	src/setup.py
10	12	src/views/file.py
0	2	src/views/file.py
        """

        stdin = io.StringIO(input)
        stdout = io.StringIO()
        modify_git_log.process(stdin, stdout)

        stdout.seek(0)
        stdin.seek(0)

        result = stdout.getvalue()

        self.assertEqual(expected, result)


if __name__ == "__main__":
    unittest.main()
