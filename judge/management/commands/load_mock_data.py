import os
from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.db import transaction
from django.conf import settings


class Command(BaseCommand):
    help = 'Load comprehensive mock data for VNOJ system'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing data before loading mock data',
        )
        parser.add_argument(
            '--languages-only',
            action='store_true',
            help='Load only language fixtures',
        )
        parser.add_argument(
            '--basic-only',
            action='store_true',
            help='Load only basic fixtures (users, organizations, problems)',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write(
                self.style.WARNING('Clearing existing data...')
            )
            self.clear_data()

        if options['languages_only']:
            self.load_languages()
        elif options['basic_only']:
            self.load_basic_data()
        else:
            self.load_all_data()

        self.stdout.write(
            self.style.SUCCESS('Mock data loaded successfully!')
        )

    def clear_data(self):
        """Clear existing data"""
        from judge.models import (
            Profile, Problem, Contest, Submission, Comment, 
            Organization, Language, Judge, BlogPost
        )
        from django.contrib.auth.models import User
        
        with transaction.atomic():
            # Clear in reverse dependency order
            Comment.objects.all().delete()
            Submission.objects.all().delete()
            Contest.objects.all().delete()
            Problem.objects.all().delete()
            BlogPost.objects.all().delete()
            Judge.objects.all().delete()
            Profile.objects.all().delete()
            Organization.objects.all().delete()
            User.objects.all().delete()
            # Keep languages as they are essential

    def load_languages(self):
        """Load language fixtures only"""
        self.stdout.write('Loading language fixtures...')
        call_command('loaddata', 'language_small.json', verbosity=0)

    def load_basic_data(self):
        """Load basic fixtures (users, organizations, problems)"""
        self.stdout.write('Loading basic mock data...')
        
        # First load languages if they don't exist
        from judge.models import Language
        if not Language.objects.exists():
            call_command('loaddata', 'language_small.json', verbosity=0)
        
        # Load comprehensive mock data
        call_command('loaddata', 'comprehensive_mock_data.json', verbosity=0)

    def load_all_data(self):
        """Load all fixtures"""
        self.stdout.write('Loading all mock data...')
        
        # Load languages first
        call_command('loaddata', 'language_small.json', verbosity=0)
        
        # Load comprehensive mock data
        call_command('loaddata', 'comprehensive_mock_data.json', verbosity=0)
        
        # Load navigation bar
        call_command('loaddata', 'navbar.json', verbosity=0)

    def create_sample_data(self):
        """Create additional sample data programmatically"""
        from judge.models import (
            Profile, Problem, Contest, Submission, Language,
            Organization, ProblemType, ProblemGroup
        )
        from django.contrib.auth.models import User
        from django.utils import timezone
        import random

        self.stdout.write('Creating additional sample data...')

        # Create more users
        for i in range(5, 21):  # Create users 5-20
            user = User.objects.create_user(
                username=f'user{i}',
                email=f'user{i}@vnoj.local',
                password='password123',
                first_name=f'User',
                last_name=f'{i}'
            )
            
            Profile.objects.create(
                user=user,
                about=f'Sample user {i}',
                language=Language.objects.first(),
                points=random.uniform(0, 100),
                performance_points=random.uniform(0, 80),
                problem_count=random.randint(0, 10)
            )

        # Create more problems
        basic_group = ProblemGroup.objects.get(name='Basic')
        basic_type = ProblemType.objects.get(name='basic')
        
        for i in range(4, 11):  # Create problems 4-10
            Problem.objects.create(
                code=f'sample{i}',
                name=f'Sample Problem {i}',
                description=f'This is sample problem {i} for testing purposes.',
                group=basic_group,
                time_limit=2.0,
                memory_limit=65536,
                points=random.uniform(5, 25),
                is_public=True,
                date=timezone.now()
            ).types.add(basic_type)

        self.stdout.write(
            self.style.SUCCESS('Additional sample data created!')
        ) 